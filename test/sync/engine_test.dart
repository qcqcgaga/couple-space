import 'dart:io';

import 'package:couple_space/core/crypto/keys.dart';
import 'package:couple_space/core/models/image.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/models/note_edit.dart';
import 'package:couple_space/core/storage/daos.dart';
import 'package:couple_space/core/storage/database.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:couple_space/core/storage/store.dart';
import 'package:couple_space/core/sync/chunk_bitmap.dart';
import 'package:couple_space/core/sync/engine.dart';
import 'package:couple_space/core/sync/sync_storage.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_connection.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SyncEngine 握手', () {
    test('未配对时双方自动接受配对码，白名单落库，二次连接无需配对', () async {
      final a = await _Harness.make('deviceA', name: '小明的手机');
      final b = await _Harness.make('deviceB', name: '小红的手机');
      addTearDown(() => _cleanup(a, b));

      // 首次连接：自动接受配对。
      final (sa, sb) = await _runSync(a, b);
      expect(await PeersDao(a.db).isPaired('deviceB'), isTrue);
      expect(await PeersDao(b.db).isPaired('deviceA'), isTrue);
      await sa.close();
      await sb.close();

      // 二次连接：白名单已存在，不再进入配对流程。
      final (sa2, sb2) = await _runSync(a, b);
      expect(sa2.peerDeviceId, 'deviceB');
      expect(sb2.peerDeviceId, 'deviceA');
      await sa2.close();
      await sb2.close();
    });

    test('配对挑战：双方计算相同 SAS，确认后完成握手', () async {
      final a = await _Harness.make('deviceA', autoAccept: false);
      final b = await _Harness.make('deviceB', autoAccept: false);
      addTearDown(() => _cleanup(a, b));

      // 先订阅配对挑战，避免握手比订阅更快导致丢事件。
      final challengesA = <PairingChallenge>[];
      final challengesB = <PairingChallenge>[];
      final subA = a.engine.onPairingChallenge.listen(challengesA.add);
      final subB = b.engine.onPairingChallenge.listen(challengesB.add);
      addTearDown(() async {
        await subA.cancel();
        await subB.cancel();
      });

      final duplex = MemoryDuplex.pair();
      final sa = await a.engine.accept(duplex.a);
      final sb = await b.engine.connect(duplex.b);

      await _waitUntil(
        () async => challengesA.isNotEmpty && challengesB.isNotEmpty,
        timeout: const Duration(seconds: 5),
      );
      expect(challengesA.single.code, challengesB.single.code);
      expect(RegExp(r'^\d{6}$').hasMatch(challengesA.single.code), isTrue);

      await a.engine.confirmPairing(challengesA.single.code);
      await b.engine.confirmPairing(challengesB.single.code);
      await Future.wait([sa.synced, sb.synced])
          .timeout(const Duration(seconds: 10));
      expect(await PeersDao(a.db).isPaired('deviceB'), isTrue);
      await sa.close();
      await sb.close();
    });

    test('身份公钥与白名单不一致时握手失败并关闭', () async {
      final a = await _Harness.make('deviceA');
      final b = await _Harness.make('deviceB');
      addTearDown(() => _cleanup(a, b));
      // 预配对时在 B 侧写入错误的 A 身份公钥。
      await PeersDao(a.db).upsert(PeerRow(
        deviceId: 'deviceB',
        name: '小红的手机',
        identityPublicKey: b.engine.identity.publicKeyBase64,
        pairedAt: 1,
      ));
      final wrongKey = await IdentityKeys.generate('evil');
      await PeersDao(b.db).upsert(PeerRow(
        deviceId: 'deviceA',
        name: '小明的手机',
        identityPublicKey: wrongKey.publicKeyBase64,
        pairedAt: 1,
      ));

      final duplex = MemoryDuplex.pair();
      final sa = await a.engine.accept(duplex.a);
      final sb = await b.engine.connect(duplex.b);
      final errors = <String>[];
      final subB = b.engine.events.listen((e) {
        if (e.kind == SyncEventKind.error) errors.add(e.message ?? '');
      });
      await Future.wait([sa.done, sb.done])
          .timeout(const Duration(seconds: 10));
      await subB.cancel();
      expect(errors.any((m) => m.contains('identity_mismatch')), isTrue);
    });

    test('未配对且未确认配对码时握手超时关闭', () async {
      final a = await _Harness.make('deviceA', autoAccept: false);
      final b = await _Harness.make('deviceB', autoAccept: false);
      addTearDown(() => _cleanup(a, b));

      // 先订阅错误事件，避免超时事件早于订阅发出。
      final errors = <String>[];
      final subA = a.engine.events.listen((e) {
        if (e.kind == SyncEventKind.error) errors.add(e.message ?? '');
      });
      addTearDown(() => subA.cancel());

      final duplex = MemoryDuplex.pair();
      final sa = await a.engine.accept(duplex.a);
      final sb = await b.engine.connect(duplex.b);
      await Future.wait([sa.done, sb.done])
          .timeout(const Duration(seconds: 10));
      expect(errors, isNotEmpty);
    });
  });

  group('SyncEngine 笔记同步', () {
    test('字段级 LWW：两端各自较新的字段在双方都胜出', () async {
      final a = await _Harness.make('deviceA');
      final b = await _Harness.make('deviceB');
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);
      final storeA = NoteStore(a.db);
      final storeB = NoteStore(b.db);

      await storeA.save(_noteWithVersions(
        id: 'n1',
        deviceId: 'deviceA',
        title: 'A 标题',
        titleTs: 3000,
        content: 'A 旧正文',
        contentTs: 1000,
      ));
      await storeB.save(_noteWithVersions(
        id: 'n1',
        deviceId: 'deviceB',
        title: 'B 旧标题',
        titleTs: 1000,
        content: 'B 正文',
        contentTs: 3000,
      ));

      final (sa, sb) = await _runSync(a, b);
      final mergedA = (await storeA.noteById('n1'))!;
      final mergedB = (await storeB.noteById('n1'))!;
      expect(mergedA.title, 'A 标题'); // A 较新
      expect(mergedA.content, 'B 正文'); // B 较新
      expect(mergedB.title, 'A 标题');
      expect(mergedB.content, 'B 正文');
      expect(
        mergedA.fieldVersions['title'],
        const FieldVersion(3000, 'deviceA'),
      );
      expect(
        mergedA.fieldVersions['content'],
        const FieldVersion(3000, 'deviceB'),
      );
      await sa.close();
      await sb.close();
    });

    test('删除传播为墓碑，另一方在删除后编辑可复活', () async {
      final a = await _Harness.make('deviceA');
      final b = await _Harness.make('deviceB');
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);
      final storeA = NoteStore(a.db);
      final storeB = NoteStore(b.db);

      await storeA.save(_stampedNote(id: 'n2', deviceId: 'deviceA', ts: 1000));
      var (sa, sb) = await _runSync(a, b);
      expect((await storeB.noteById('n2'))?.deleted, isFalse);
      await sa.close();
      await sb.close();

      // A 删除（ts=2000），同步后 B 侧墓碑。
      await storeA.delete('n2', deviceId: 'deviceA', ts: 2000);
      (sa, sb) = await _runSync(a, b);
      expect((await storeB.noteById('n2'))!.deleted, isTrue);
      expect((await TombstonesDao(b.db).all()).map((t) => t.recordId), contains('n2'));
      await sa.close();
      await sb.close();

      // B 在删除之后编辑（ts=3000，覆盖 deleted 字段版本）→ 笔记复活。
      await storeB.save(_stampedNote(
        id: 'n2',
        deviceId: 'deviceB',
        ts: 3000,
        content: 'B 复活正文',
      ));
      (sa, sb) = await _runSync(a, b);
      expect((await storeA.noteById('n2'))!.deleted, isFalse);
      expect((await storeB.noteById('n2'))!.content, 'B 复活正文');
      await sa.close();
      await sb.close();
    });
  });

  group('SyncEngine 图片传输', () {
    test('全量分块传输：B 收到完整文件并校验哈希', () async {
      final a = await _Harness.make('deviceA', chunkSize: 64 * 1024);
      final b = await _Harness.make('deviceB', chunkSize: 64 * 1024);
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);

      final bytes = _bytes(200000);
      final meta = await _addLocalImage(a, bytes);
      final (sa, sb) = await _runSync(a, b);

      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.syncStatus == 'done',
        timeout: const Duration(seconds: 10),
      );
      final bImage = (await ImagesDao(b.db).imageById('img1'))!;
      expect(bImage.sha256, meta.sha256);
      expect(bImage.totalChunks, 4);
      expect(await b.files.exists(bImage), isTrue);
      expect(await b.files.size(bImage), bytes.length);
      expect(await b.files.sha256(bImage), meta.sha256);
      expect((await b.files.readChunk(bImage, 0, bytes.length)), bytes);

      final queue = await ImageTransfersDao(a.db).find('deviceB', 'img1');
      expect(queue!.status, 'done');
      await sa.close();
      await sb.close();
    });

    test('断点续传：首轮只发前两块，重连后补齐剩余块', () async {
      final a = await _Harness.make('deviceA', chunkSize: 64 * 1024, maxChunks: 2);
      final b = await _Harness.make('deviceB', chunkSize: 64 * 1024);
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);

      final bytes = _bytes(200000);
      await _addLocalImage(a, bytes);

      // 第一轮：只发送 2/4 块。
      var (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async {
          final image = await ImagesDao(b.db).imageById('img1');
          return image != null &&
              image.syncStatus == 'partial' &&
              ChunkBitmap.receivedCount(image.chunkBitmap, image.totalChunks) >= 2;
        },
        timeout: const Duration(seconds: 10),
      );
      await sa.close();
      await sb.close();

      final partial = (await ImagesDao(b.db).imageById('img1'))!;
      expect(partial.syncStatus, 'partial');
      expect(ChunkBitmap.receivedCount(partial.chunkBitmap, partial.totalChunks), 2);

      // 第二轮：从缺失块继续，收齐并校验。
      (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.syncStatus == 'done',
        timeout: const Duration(seconds: 10),
      );
      final done = (await ImagesDao(b.db).imageById('img1'))!;
      expect(await b.files.sha256(done), done.sha256);
      expect(await b.files.size(done), bytes.length);
      await sa.close();
      await sb.close();
    });

    test('哈希校验失败后整图重传', () async {
      final a = await _Harness.make('deviceA', chunkSize: 64 * 1024);
      final b = await _Harness.make('deviceB', chunkSize: 64 * 1024);
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);

      final bytes = _bytes(70000);
      final meta = await _addLocalImage(a, bytes);
      var (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.syncStatus == 'done',
        timeout: const Duration(seconds: 10),
      );
      await sa.close();
      await sb.close();

      // 模拟此前哈希校验失败：标记 failed 并清空位图。
      await ImagesDao(b.db).markFailed('img1', error: 'hash_mismatch');

      (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.syncStatus == 'done',
        timeout: const Duration(seconds: 10),
      );
      final done = (await ImagesDao(b.db).imageById('img1'))!;
      expect(done.sha256, meta.sha256);
      expect(await b.files.sha256(done), meta.sha256);
      await sa.close();
      await sb.close();
    });

    test('图片删除传播：B 侧标记删除并删除本地文件', () async {
      final a = await _Harness.make('deviceA', chunkSize: 64 * 1024);
      final b = await _Harness.make('deviceB', chunkSize: 64 * 1024);
      addTearDown(() => _cleanup(a, b));
      await _prePair(a, b);

      await _addLocalImage(a, _bytes(70000));
      var (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.syncStatus == 'done',
        timeout: const Duration(seconds: 10),
      );
      await sa.close();
      await sb.close();

      await ImagesDao(a.db).markDeleted('img1', deviceId: 'deviceA', ts: 5000);
      (sa, sb) = await _runSync(a, b);
      await _waitUntil(
        () async => (await ImagesDao(b.db).imageById('img1'))?.deleted == true,
        timeout: const Duration(seconds: 10),
      );
      final deleted = (await ImagesDao(b.db).imageById('img1'))!;
      expect(deleted.deleted, isTrue);
      expect(await b.files.exists(deleted), isFalse);
      await sa.close();
      await sb.close();
    });
  });
}

// ---------- 测试辅助 ----------

class _Harness {
  _Harness(this.db, this.engine, this.dir);

  final AppDatabase db;
  final SyncEngine engine;
  final Directory dir;

  DiskImageFileStore get files => engine.imageFiles as DiskImageFileStore;

  static Future<_Harness> make(
    String deviceId, {
    String name = '',
    bool autoAccept = true,
    int? maxChunks,
    int chunkSize = 64 * 1024,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final identity = await IdentityKeys.generate(deviceId);
    final dir = await Directory.systemTemp.createTemp('couple_space_engine');
    final files = DiskImageFileStore(dir);
    final engine = SyncEngine(
      storage: DriftSyncStorage(db),
      identity: identity,
      imageFiles: files,
      options: SyncEngineOptions(
        deviceName: name,
        autoAcceptPairing: autoAccept,
        maxImageChunksPerSession: maxChunks,
        chunkSize: chunkSize,
        handshakeTimeout: const Duration(seconds: 5),
      ),
    );
    return _Harness(db, engine, dir);
  }
}

Future<void> _cleanup(_Harness a, _Harness b) async {
  await a.engine.closeAll();
  await b.engine.closeAll();
  await a.db.close();
  await b.db.close();
  for (final dir in [a.dir, b.dir]) {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}

Future<void> _prePair(_Harness a, _Harness b) async {
  await PeersDao(a.db).upsert(PeerRow(
    deviceId: b.engine.identity.deviceId,
    name: '小红的手机',
    identityPublicKey: b.engine.identity.publicKeyBase64,
    pairedAt: 1,
  ));
  await PeersDao(b.db).upsert(PeerRow(
    deviceId: a.engine.identity.deviceId,
    name: '小明的手机',
    identityPublicKey: a.engine.identity.publicKeyBase64,
    pairedAt: 1,
  ));
}

Future<(SyncSession, SyncSession)> _runSync(_Harness a, _Harness b) async {
  final duplex = MemoryDuplex.pair();
  final sa = await a.engine.accept(duplex.a);
  final sb = await b.engine.connect(duplex.b);
  await Future.wait([sa.synced, sb.synced])
      .timeout(const Duration(seconds: 15));
  return (sa, sb);
}

Note _stampedNote({
  required String id,
  required String deviceId,
  required int ts,
  String? title,
  String content = '一起写下的正文',
}) {
  return NoteVersions.stamped(
    Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime.fromMillisecondsSinceEpoch(ts),
      createdBy: deviceId,
    ),
    deviceId: deviceId,
    ts: ts,
  );
}

/// 按字段显式设置 LWW 版本（用于验证字段级合并）。
Note _noteWithVersions({
  required String id,
  required String deviceId,
  required String title,
  required int titleTs,
  required String content,
  required int contentTs,
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
    createdBy: deviceId,
    fieldVersions: {
      'title': FieldVersion(titleTs, deviceId),
      'content': FieldVersion(contentTs, deviceId),
    },
  );
}

Future<ImageMeta> _addLocalImage(_Harness h, Uint8List bytes) async {
  final hash = await Sha256().hash(bytes);
  final sha = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  final chunkSize = h.engine.options.effectiveChunkSize;
  final meta = ImageMeta(
    id: 'img1',
    noteId: 'n1',
    fileName: 'photo.jpg',
    sha256: sha,
    size: bytes.length,
    syncStatus: 'done',
    chunkSize: chunkSize,
    totalChunks: (bytes.length + chunkSize - 1) ~/ chunkSize,
    chunkBitmap: ChunkBitmap.allOneText((bytes.length + chunkSize - 1) ~/ chunkSize),
    lwTs: 1000,
    lwDevice: h.engine.identity.deviceId,
  );
  await h.files.writeChunk(meta, 0, bytes);
  await ImagesDao(h.db).upsertImage(meta);
  return meta;
}

Uint8List _bytes(int length) =>
    Uint8List.fromList(List.generate(length, (i) => i % 251));

Future<void> _waitUntil(
  Future<bool> Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(await condition(), isTrue, reason: '等待条件超时');
}
