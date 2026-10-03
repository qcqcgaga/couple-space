import 'dart:async';
import 'dart:io';

import 'package:couple_space/core/crypto/keys.dart';
import 'package:couple_space/core/pairing/qr_codec.dart';
import 'package:couple_space/core/storage/daos.dart';
import 'package:couple_space/core/storage/database.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:couple_space/core/sync/engine.dart';
import 'package:couple_space/core/sync/sync_storage.dart';
import 'package:couple_space/core/sync/transports/transport.dart';
import 'package:couple_space/platform/bluetooth.dart';
import 'package:couple_space/platform/multicast_lock.dart';
import 'package:couple_space/platform/permissions.dart';
import 'package:couple_space/services/sync_service.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_transport.dart';
import '../helpers/memory_connection.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late List<Future<void> Function()> cleanups;

  setUp(() => cleanups = []);
  tearDown(() async {
    for (final cleanup in cleanups.reversed) {
      await cleanup();
    }
  });

  group('SyncService 局域网接入', () {
    test('发现已配对设备自动连接并完成同步（无配对挑战）', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);
      await _prePair(ctx.db, peer, ctx.service.identity);

      _wireConnect(ctx, peer);
      await ctx.service.start();
      ctx.transport.emitDiscovery(
        const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
      );

      await _waitUntil(() async => ctx.service.isConnected('deviceB'));
      expect(ctx.transport.connectedPeerIds, contains('deviceB'));
      expect(ctx.service.pendingChallenge, isNull);
      expect(await ctx.service.watchPeers().first, hasLength(1));
    });

    test('未配对设备不自动连接；手动配对按钮发起并完成配对', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);

      _wireConnect(ctx, peer);
      await ctx.service.start();
      ctx.transport.emitDiscovery(
        const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      // 未配对：只展示、不自动连接。
      expect(ctx.transport.connectedPeerIds, isEmpty);

      await ctx.service.connectToDiscovered('deviceB');
      await _waitUntil(() async => ctx.service.pendingChallenge != null);
      final challenge = ctx.service.pendingChallenge!;
      expect(challenge.verifiedByQr, isFalse);
      expect(RegExp(r'^\d{6}$').hasMatch(challenge.code), isTrue);

      await ctx.service.confirmPairing(challenge.code);
      await _waitUntil(() async => PeersDao(ctx.db).isPaired('deviceB'));
      expect(
        await peer.storage.isPaired('deviceA'),
        isTrue,
        reason: '对方侧也应写入白名单',
      );
    });

    test('二维码锁定身份后自动连接，挑战带 verifiedByQr 标记', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);

      _wireConnect(ctx, peer);
      await ctx.service.start();
      ctx.transport.emitDiscovery(
        const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await ctx.service.prepareQrPairing(PairQrData(
        deviceId: 'deviceB',
        name: '小红',
        identityPublicKey: peer.engine.identity.publicKeyBase64,
      ));
      await _waitUntil(() async => ctx.service.pendingChallenge != null);
      final challenge = ctx.service.pendingChallenge!;
      expect(challenge.verifiedByQr, isTrue);

      await ctx.service.confirmPairing(challenge.code);
      await _waitUntil(() async => PeersDao(ctx.db).isPaired('deviceB'));
    });

    test('二维码公钥与对端不一致：连接失败且不弹挑战', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);

      _wireConnect(ctx, peer);
      await ctx.service.start();
      final wrong = await IdentityKeys.generate('evil');
      await ctx.service.prepareQrPairing(PairQrData(
        deviceId: 'deviceB',
        identityPublicKey: wrong.publicKeyBase64,
      ));
      await ctx.service.connectToDiscovered('deviceB');

      await _waitUntil(() async =>
          ctx.service.recentEvents.any((e) =>
              e.kind == SyncEventKind.error &&
              (e.message ?? '').contains('identity_mismatch')));
      expect(ctx.service.pendingChallenge, isNull);
      expect(await PeersDao(ctx.db).isPaired('deviceB'), isFalse);
    });

    test('手动 IP 直连可完成配对（绕过发现）', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);

      ctx.transport.onConnectHost = (host, port) {
        final duplex = MemoryDuplex.pair();
        unawaited(peer.engine.accept(duplex.b));
        return Future.value(duplex);
      };
      await ctx.service.start();
      await ctx.service.connectToHost('192.168.1.8', 4321);

      await _waitUntil(() async => ctx.service.pendingChallenge != null);
      final challenge = ctx.service.pendingChallenge!;
      await ctx.service.confirmPairing(challenge.code);
      await _waitUntil(() async => PeersDao(ctx.db).isPaired('deviceB'));
      expect(ctx.transport.connectedHosts, contains(('192.168.1.8', 4321)));
    });

    test('解除配对移除白名单并关闭会话', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);
      await _prePair(ctx.db, peer, ctx.service.identity);

      _wireConnect(ctx, peer);
      await ctx.service.start();
      ctx.transport.emitDiscovery(
        const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
      );
      await _waitUntil(() async => ctx.service.isConnected('deviceB'));

      await ctx.service.unpair('deviceB');
      expect(await PeersDao(ctx.db).isPaired('deviceB'), isFalse);
      expect(ctx.service.isConnected('deviceB'), isFalse);
    });

    test('关闭自动连接后仅手动发起有效', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      final peer = await _PeerHarness.create('deviceB');
      cleanups.add(peer.dispose);
      await _prePair(ctx.db, peer, ctx.service.identity);

      _wireConnect(ctx, peer);
      await ctx.service.setAutoConnect(false);
      expect(
        await SyncStateDao(ctx.db).getBool('auto_connect', fallback: true),
        isFalse,
      );
      await ctx.service.start();

      ctx.transport.emitDiscovery(
        const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(ctx.transport.connectedPeerIds, isEmpty);

      await ctx.service.connectToDiscovered('deviceB');
      await _waitUntil(() async => ctx.service.isConnected('deviceB'));
    });

    test('设备昵称持久化到 sync_state', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      await ctx.service.setDeviceName('小明的手机');
      expect(ctx.service.deviceName, '小明的手机');
      expect(await SyncStateDao(ctx.db).get('device_name'), '小明的手机');
    });
  });

  group('SyncService 蓝牙入口', () {
    test('原生未实现时提示待真机联调，不影响其它状态', () async {
      final ctx = await _Context.create();
      cleanups.add(ctx.dispose);
      await ctx.service.start();
      await ctx.service.startBluetoothScan();
      expect(ctx.service.lastError, contains('待真机联调'));
      expect(ctx.service.bluetoothScanning, isFalse);
    });
  });
}

// ---------- 测试辅助 ----------

class _Context {
  _Context({
    required this.db,
    required this.service,
    required this.transport,
    required this.dir,
  });

  final AppDatabase db;
  final SyncService service;
  final FakeTransport transport;
  final Directory dir;

  static Future<_Context> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    final identity = await IdentityKeys.generate('deviceA');
    final dir = await Directory.systemTemp.createTemp('couple_space_service');
    final transport = FakeTransport();
    final service = SyncService(
      db: db,
      identity: identity,
      imageFiles: DiskImageFileStore(dir),
      transportFactory: (_, _) => transport,
      multicastLock: const NoopMulticastLock(),
      permissionRequester: const NoopPermissionRequester(),
      bluetooth: _FakeBluetoothChannel(),
      engineOptions: const SyncEngineOptions(
        handshakeTimeout: Duration(seconds: 5),
      ),
    );
    return _Context(db: db, service: service, transport: transport, dir: dir);
  }

  Future<void> dispose() async {
    await service.stop();
    await db.close();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}

/// 假蓝牙通道：模拟原生未实现（isAvailable=false），不触碰 MethodChannel。
class _FakeBluetoothChannel implements BluetoothChannel {
  @override
  Future<bool> get isAvailable async => false;

  @override
  Stream<PeerDiscovered> get onPeerDiscovered => const Stream.empty();

  @override
  Future<void> startScan({
    required String deviceId,
    required String deviceName,
  }) async {}

  @override
  Future<void> stopScan() async {}

  @override
  Future<Connection> connect(String peerId) async {
    throw UnsupportedError('假通道不支持连接');
  }
}

class _PeerHarness {
  _PeerHarness({required this.storage, required this.engine, required this.dir});

  final MemorySyncStorage storage;
  final SyncEngine engine;
  final Directory dir;

  static Future<_PeerHarness> create(String deviceId) async {
    final storage = MemorySyncStorage();
    final identity = await IdentityKeys.generate(deviceId);
    final dir = await Directory.systemTemp.createTemp('couple_space_peer');
    final engine = SyncEngine(
      storage: storage,
      identity: identity,
      imageFiles: DiskImageFileStore(dir),
      options: SyncEngineOptions(
        deviceName: '小红的手机',
        autoAcceptPairing: true,
        handshakeTimeout: const Duration(seconds: 5),
      ),
    );
    return _PeerHarness(storage: storage, engine: engine, dir: dir);
  }

  Future<void> dispose() async {
    await engine.closeAll();
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }
}

Future<void> _prePair(
  AppDatabase db,
  _PeerHarness peer,
  IdentityKeys appIdentity,
) async {
  await PeersDao(db).upsert(PeerRow(
    deviceId: peer.engine.identity.deviceId,
    name: '小红的手机',
    identityPublicKey: peer.engine.identity.publicKeyBase64,
    pairedAt: 1,
  ));
  await peer.storage.upsertPeer(
    deviceId: appIdentity.deviceId,
    name: '小明',
    identityPublicKey: appIdentity.publicKeyBase64,
  );
}

void _wireConnect(_Context ctx, _PeerHarness peer) {
  ctx.transport.onConnect = (peerId) {
    final duplex = MemoryDuplex.pair();
    unawaited(peer.engine.accept(duplex.b));
    return Future.value(duplex);
  };
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
