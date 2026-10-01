// 探针 A：本机双进程协议自测（docs/03-test-env.md §4）。
//
// 两个 Dart 进程通过真实 mDNS 发现彼此，再用 TCP + 分帧协议交换
// Hello / PeerInfo，验证「发现 + TCP + 分帧」在局域网（本机回环亦可）工作。
//
// 用法：
//   dart run tool/probe.dart server --id probe-server --name 探针服务器
//   dart run tool/probe.dart client --find probe-server --name 探针客户端
//
// 同步引擎模式（M1 图片分块 + 同步引擎编排的双进程自测）：
//   dart run tool/probe.dart sync-server --id sync-server --name 同步服务器 --mdns-port 55353
//   dart run tool/probe.dart sync-client --find sync-server --id sync-client --name 同步客户端 --mdns-port 55353

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:couple_space/core/crypto/keys.dart';
import 'package:couple_space/core/models/image.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/models/note_edit.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:couple_space/core/sync/chunk_bitmap.dart';
import 'package:couple_space/core/sync/engine.dart';
import 'package:couple_space/core/sync/sync_storage.dart';
import 'package:couple_space/core/sync/protocol/codec.dart';
import 'package:couple_space/core/sync/protocol/frames.dart';
import 'package:couple_space/core/sync/transports/lan/lan_transport.dart';
import 'package:cryptography/cryptography.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'server' : args[0];
  try {
    switch (mode) {
      case 'server':
        await _runServer(args.skip(1).toList());
      case 'client':
        await _runClient(args.skip(1).toList());
      case 'sync-server':
        await _runSyncServer(args.skip(1).toList());
      case 'sync-client':
        await _runSyncClient(args.skip(1).toList());
      default:
        stderr.writeln(
            '用法: dart run tool/probe.dart <server|client|sync-server|sync-client> [--id ..] [--name ..] [--find ..]');
        exit(2);
    }
  } catch (e, s) {
    stderr.writeln('ERROR: $e\n$s');
    exit(1);
  }
}

// ---------- 同步引擎模式（真实 mDNS + TCP + 配对 + 笔记/图片同步） ----------

Future<void> _runSyncServer(List<String> args) async {
  final deviceId = _value(args, 'id') ?? 'sync-${DateTime.now().millisecondsSinceEpoch}';
  final name = _value(args, 'name') ?? '同步服务器';
  final mdnsPort = int.tryParse(_value(args, 'mdns-port') ?? '') ?? 5353;
  final chunkSize = int.tryParse(_value(args, 'chunk-size') ?? '') ?? 64 * 1024;

  final storage = MemorySyncStorage();
  final identity = await IdentityKeys.generate(deviceId);
  final imagesDir = await Directory.systemTemp.createTemp('probe_sync_images');
  final files = DiskImageFileStore(imagesDir);
  final engine = SyncEngine(
    storage: storage,
    identity: identity,
    imageFiles: files,
    options: SyncEngineOptions(
      deviceName: name,
      autoAcceptPairing: true,
      chunkSize: chunkSize,
      handshakeTimeout: const Duration(seconds: 30),
    ),
  );

  // 预置一条笔记与一张 3 块图片（分块大小 64 KB）。
  await storage.saveNote(NoteVersions.stamped(
    Note(
      id: 'probe-note',
      title: '探针笔记',
      content: '来自同步服务器的笔记',
      createdAt: DateTime.now(),
      createdBy: deviceId,
    ),
    deviceId: deviceId,
    ts: DateTime.now().millisecondsSinceEpoch,
  ));
  final imageBytes = Uint8List.fromList(
    List.generate(160 * 1024 + 17, (i) => (i * 31) % 251),
  );
  final hash = await Sha256().hash(imageBytes);
  final sha = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final image = ImageMeta(
    id: 'probe-image',
    noteId: 'probe-note',
    fileName: 'probe.jpg',
    sha256: sha,
    size: imageBytes.length,
    syncStatus: 'done',
    chunkSize: chunkSize,
    totalChunks: (imageBytes.length + chunkSize - 1) ~/ chunkSize,
    chunkBitmap: ChunkBitmap.allOneText((imageBytes.length + chunkSize - 1) ~/ chunkSize),
    lwTs: DateTime.now().millisecondsSinceEpoch,
    lwDevice: deviceId,
  );
  await files.writeChunk(image, 0, imageBytes);
  await storage.upsertImage(image);

  final transport = LanTransport(
    deviceId: deviceId,
    deviceName: name,
    discoveryInterval: const Duration(seconds: 2),
    mdnsPort: mdnsPort,
  );
  await transport.start();
  _out('READY id=$deviceId name=$name port=${transport.port}');

  final connection = await transport.onIncoming.first
      .timeout(const Duration(seconds: 90));
  final session = await engine.accept(connection);
  await session.synced.timeout(const Duration(seconds: 90));
  // 图片字节与笔记独立同步：等待发送队列完成再关闭，避免客户端缺块。
  final transferDone = Completer<void>();
  final eventsSub = engine.events.listen((event) {
    if (event.imageId == image.id) {
      if (event.kind == SyncEventKind.imageTransferDone && !transferDone.isCompleted) {
        transferDone.complete();
      } else if (event.kind == SyncEventKind.imageTransferFailed &&
          !transferDone.isCompleted) {
        transferDone.completeError(StateError('图片发送失败: ${event.message}'));
      }
    }
  });
  try {
    await transferDone.future.timeout(const Duration(seconds: 90));
  } finally {
    await eventsSub.cancel();
  }
  _out('SERVER-SYNC-OK peer=${session.peerDeviceId ?? ''} note=probe-note image=probe-image size=${imageBytes.length}');
  await session.close();
  await transport.stop();
  await _outQueue;
  if (await imagesDir.exists()) {
    await imagesDir.delete(recursive: true);
  }
  exit(0);
}

Future<void> _runSyncClient(List<String> args) async {
  final find = _value(args, 'find') ?? '';
  if (find.isEmpty) {
    stderr.writeln('sync-client 模式需要 --find <设备ID或名称>');
    exit(2);
  }
  final deviceId = _value(args, 'id') ?? 'sync-${DateTime.now().millisecondsSinceEpoch}';
  final name = _value(args, 'name') ?? '同步客户端';
  final mdnsPort = int.tryParse(_value(args, 'mdns-port') ?? '') ?? 5353;
  final chunkSize = int.tryParse(_value(args, 'chunk-size') ?? '') ?? 64 * 1024;

  final storage = MemorySyncStorage();
  final identity = await IdentityKeys.generate(deviceId);
  final imagesDir = await Directory.systemTemp.createTemp('probe_sync_images');
  final files = DiskImageFileStore(imagesDir);
  final engine = SyncEngine(
    storage: storage,
    identity: identity,
    imageFiles: files,
    options: SyncEngineOptions(
      deviceName: name,
      autoAcceptPairing: true,
      chunkSize: chunkSize,
      handshakeTimeout: const Duration(seconds: 30),
    ),
  );

  final transport = LanTransport(
    deviceId: deviceId,
    deviceName: name,
    discoveryInterval: const Duration(seconds: 2),
    mdnsPort: mdnsPort,
  );
  await transport.start();

  final peer = await transport.onPeerDiscovered
      .firstWhere(
        (p) => p.peerId == find || p.name == find,
        orElse: () => throw StateError('未发现设备: $find'),
      )
      .timeout(const Duration(seconds: 90));
  _out('CLIENT-FOUND ${peer.peerId} name=${peer.name ?? ''}');

  final connection = await transport.connect(peer.peerId);
  final session = await engine.connect(connection);
  await session.synced.timeout(const Duration(seconds: 90));

  // 等待笔记与图片都落地（图片字节与笔记独立同步）。
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    final note = await storage.noteById('probe-note');
    final imageRow = await storage.imageById('probe-image');
    if (note != null &&
        imageRow != null &&
        imageRow.syncStatus == 'done' &&
        await files.exists(imageRow) &&
        await files.sha256(imageRow) == imageRow.sha256) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final note = await storage.noteById('probe-note');
  final imageRow = await storage.imageById('probe-image');
  if (note == null || imageRow == null || imageRow.syncStatus != 'done') {
    stderr.writeln('同步未收敛：note=${note != null} image=${imageRow?.syncStatus}');
    exit(1);
  }
  final size = await files.size(imageRow);
  _out('CLIENT-SYNC-OK peer=${session.peerDeviceId ?? ''} note=probe-note image=probe-image size=$size');

  await session.close();
  await transport.stop();
  await _outQueue;
  if (await imagesDir.exists()) {
    await imagesDir.delete(recursive: true);
  }
  exit(0);
}


Future<void> _runServer(List<String> args) async {
  final deviceId = _value(args, 'id') ?? 'probe-${DateTime.now().millisecondsSinceEpoch}';
  final name = _value(args, 'name') ?? '探针服务器';
  final mdnsPort = int.tryParse(_value(args, 'mdns-port') ?? '') ?? 5353;

  final transport = LanTransport(
    deviceId: deviceId,
    deviceName: name,
    discoveryInterval: const Duration(seconds: 2),
    mdnsPort: mdnsPort,
  );
  await transport.start();
  _out('READY id=$deviceId name=$name port=${transport.port}');

  final connection = await transport.onIncoming.first
      .timeout(const Duration(seconds: 60));
  final channel = FrameChannel(connection);
  final received = <SyncFrame>[];
  final done = Completer<void>();
  final sub = channel.frames.listen(
    (frame) {
      received.add(frame);
      if (frame is HelloFrame) {
        _out('SERVER-HELLO ${frame.deviceId}');
      }
      if (frame is ByeFrame) {
        done.complete();
      }
    },
    onDone: () {
      if (!done.isCompleted) done.complete();
    },
  );
  channel.start();

  await channel.frames
      .firstWhere((f) => f is HelloFrame)
      .timeout(const Duration(seconds: 30));
  await channel.sendFrame(
    const PeerInfoFrame(deviceId: 'probe-server', name: '探针服务器'),
  );
  await channel.sendFrame(const AckFrame(ok: true, message: '握手完成'));

  await done.future.timeout(const Duration(seconds: 30));
  await sub.cancel();
  await channel.close();
  await transport.stop();
  _out('SERVER-OK');
  await _outQueue;
  exit(0);
}

Future<void> _runClient(List<String> args) async {
  final find = _value(args, 'find') ?? '';
  if (find.isEmpty) {
    stderr.writeln('client 模式需要 --find <设备ID或名称>');
    exit(2);
  }
  final deviceId = _value(args, 'id') ?? 'probe-${DateTime.now().millisecondsSinceEpoch}';
  final name = _value(args, 'name') ?? '探针客户端';
  final mdnsPort = int.tryParse(_value(args, 'mdns-port') ?? '') ?? 5353;

  final transport = LanTransport(
    deviceId: deviceId,
    deviceName: name,
    discoveryInterval: const Duration(seconds: 2),
    mdnsPort: mdnsPort,
  );
  await transport.start();

  final peer = await transport.onPeerDiscovered
      .firstWhere(
        (p) => p.peerId == find || p.name == find,
        orElse: () => throw StateError('未发现设备: $find'),
      )
      .timeout(const Duration(seconds: 60));
  _out('CLIENT-FOUND ${peer.peerId} name=${peer.name ?? ''}');

  final connection = await transport.connect(peer.peerId);
  final channel = FrameChannel(connection);
  final frames = <SyncFrame>[];
  final sub = channel.frames.listen(frames.add);
  channel.start();

  await channel.sendFrame(
    HelloFrame(
      deviceId: deviceId,
      appVersion: '0.1.0',
      protocolVersion: 1,
      identityPublicKey: 'cHJvYmU=',
    ),
  );
  final reply = await channel.frames
      .firstWhere((f) => f is PeerInfoFrame)
      .timeout(const Duration(seconds: 30));
  final peerInfo = reply as PeerInfoFrame;
  _out('CLIENT-SYNC-OK remote=${peerInfo.deviceId} name=${peerInfo.name ?? ''}');

  await channel.sendFrame(const ByeFrame(reason: 'probe-done'));
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await sub.cancel();
  await channel.close();
  await transport.stop();
  _out('CLIENT-DONE');
  await _outQueue;
  exit(0);
}

String? _value(List<String> args, String key) {
  final index = args.indexOf('--$key');
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

Future<void> _outQueue = Future<void>.value();

void _out(String line) {
  // 串行化写入：Windows 重定向下 stdout.flush() 与下一次写入竞态会报
  // “StreamSink is bound to a stream”，逐条排队避免。
  _outQueue = _outQueue.then((_) async {
    try {
      stdout.writeln(line);
      await stdout.flush();
    } catch (_) {
      // 单条输出失败不影响后续输出（测试按行匹配）。
    }
  });
}
