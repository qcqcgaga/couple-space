// 探针 A：本机双进程协议自测（docs/03-test-env.md §4）。
//
// 两个 Dart 进程通过真实 mDNS 发现彼此，再用 TCP + 分帧协议交换
// Hello / PeerInfo，验证「发现 + TCP + 分帧」在局域网（本机回环亦可）工作。
//
// 用法：
//   dart run tool/probe.dart server --id probe-server --name 探针服务器
//   dart run tool/probe.dart client --find probe-server --name 探针客户端

import 'dart:async';
import 'dart:io';

import 'package:couple_space/core/sync/protocol/codec.dart';
import 'package:couple_space/core/sync/protocol/frames.dart';
import 'package:couple_space/core/sync/transports/lan/lan_transport.dart';

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'server' : args[0];
  try {
    switch (mode) {
      case 'server':
        await _runServer(args.skip(1).toList());
      case 'client':
        await _runClient(args.skip(1).toList());
      default:
        stderr.writeln('用法: dart run tool/probe.dart <server|client> [--id ..] [--name ..] [--find ..]');
        exit(2);
    }
  } catch (e, s) {
    stderr.writeln('ERROR: $e\n$s');
    exit(1);
  }
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
  exit(0);
}

String? _value(List<String> args, String key) {
  final index = args.indexOf('--$key');
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

void _out(String line) {
  stdout.writeln(line);
  stdout.flush();
}
