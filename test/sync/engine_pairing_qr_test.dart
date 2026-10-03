import 'dart:io';

import 'package:couple_space/core/crypto/keys.dart';
import 'package:couple_space/core/storage/daos.dart';
import 'package:couple_space/core/storage/database.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:couple_space/core/sync/engine.dart';
import 'package:couple_space/core/sync/sync_storage.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_connection.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('SyncEngine 二维码配对期望', () {
    test('二维码锁定正确身份：SAS 确认后双方白名单落库', () async {
      final a = await _Harness.make('deviceA', autoAccept: false);
      final b = await _Harness.make('deviceB', autoAccept: true);
      addTearDown(() => _cleanup(a, b));

      // 扫码方（A）锁定 B 的身份公钥，仍须人工确认 SAS。
      a.engine.prepareQrPairing('deviceB', b.engine.identity.publicKeyBase64);

      final challenges = <PairingChallenge>[];
      final sub = a.engine.onPairingChallenge.listen(challenges.add);
      addTearDown(() => sub.cancel());

      final duplex = MemoryDuplex.pair();
      final sa = await a.engine.accept(duplex.a);
      final sb = await b.engine.connect(duplex.b);

      await _waitUntil(() async => challenges.isNotEmpty);
      final challenge = challenges.single;
      expect(challenge.verifiedByQr, isTrue);
      expect(RegExp(r'^\d{6}$').hasMatch(challenge.code), isTrue);

      await a.engine.confirmPairing(challenge.code);
      await Future.wait([sa.synced, sb.synced])
          .timeout(const Duration(seconds: 10));
      expect(await PeersDao(a.db).isPaired('deviceB'), isTrue);
      expect(await PeersDao(b.db).isPaired('deviceA'), isTrue);
      await sa.close();
      await sb.close();
    });

    test('二维码公钥与对端不一致：配对失败且不弹挑战', () async {
      final a = await _Harness.make('deviceA', autoAccept: false);
      final b = await _Harness.make('deviceB', autoAccept: true);
      addTearDown(() => _cleanup(a, b));

      final wrong = await IdentityKeys.generate('evil');
      a.engine.prepareQrPairing('deviceB', wrong.publicKeyBase64);

      final challenges = <PairingChallenge>[];
      final errors = <String>[];
      final subC = a.engine.onPairingChallenge.listen(challenges.add);
      final subE = a.engine.events.listen((e) {
        if (e.kind == SyncEventKind.error) errors.add(e.message ?? '');
      });
      addTearDown(() async {
        await subC.cancel();
        await subE.cancel();
      });

      final duplex = MemoryDuplex.pair();
      final sa = await a.engine.accept(duplex.a);
      final sb = await b.engine.connect(duplex.b);
      await Future.wait([sa.done, sb.done])
          .timeout(const Duration(seconds: 10));

      expect(challenges, isEmpty);
      expect(errors.any((m) => m.contains('identity_mismatch')), isTrue);
      expect(await PeersDao(a.db).isPaired('deviceB'), isFalse);
    });
  });
}

class _Harness {
  _Harness(this.db, this.engine, this.dir);

  final AppDatabase db;
  final SyncEngine engine;
  final Directory dir;

  static Future<_Harness> make(
    String deviceId, {
    bool autoAccept = true,
  }) async {
    final db = AppDatabase(NativeDatabase.memory());
    final identity = await IdentityKeys.generate(deviceId);
    final dir = await Directory.systemTemp.createTemp('couple_space_qr_engine');
    final engine = SyncEngine(
      storage: DriftSyncStorage(db),
      identity: identity,
      imageFiles: DiskImageFileStore(dir),
      options: SyncEngineOptions(
        deviceName: deviceId,
        autoAcceptPairing: autoAccept,
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

Future<void> _waitUntil(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  expect(await condition(), isTrue, reason: '等待条件超时');
}
