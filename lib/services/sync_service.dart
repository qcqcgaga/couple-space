import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/crypto/keys.dart';
import '../core/pairing/qr_codec.dart';
import '../core/storage/daos.dart';
import '../core/storage/database.dart';
import '../core/storage/image_files.dart';
import '../core/sync/engine.dart';
import '../core/sync/sync_storage.dart';
import '../core/sync/transports/lan/lan_transport.dart';
import '../core/sync/transports/transport.dart';
import '../platform/bluetooth.dart';
import '../platform/multicast_lock.dart';
import '../platform/permissions.dart';

/// 传输工厂：生产创建 LanTransport（mDNS + TCP），测试注入假传输。
typedef SyncTransportFactory = Transport Function(
  String deviceId,
  String deviceName,
);

/// M3 同步接入：把 M1 同步引擎装配进 App（ADR-029）。
///
/// 职责：
/// - 启动 LanTransport（mDNS 发现 + TCP 监听）；蓝牙/热点复用同一引擎；
/// - 白名单自动连接：发现已配对设备自动建连，陌生设备仅展示；
/// - 配对流程：SAS 挑战分发到 UI、二维码身份锁定、confirmPairing 转发；
/// - 会话去重：每个对端只保留一个活跃会话（握手后按 peerDeviceId 收敛）；
/// - 设备昵称与自动连接开关持久化（sync_state 键值）。
class SyncService extends ChangeNotifier {
  SyncService({
    required this.db,
    required this.identity,
    required this.imageFiles,
    SyncTransportFactory? transportFactory,
    MulticastLock? multicastLock,
    PermissionRequester? permissionRequester,
    BluetoothChannel? bluetooth,
    SyncEngine? engine,
    this.engineOptions = const SyncEngineOptions(),
  })  : _transportFactory = transportFactory ?? _defaultTransportFactory,
        _multicastLock = multicastLock ?? MethodChannelMulticastLock(),
        _permissions = permissionRequester ?? ChannelPermissionRequester(),
        _bluetooth = bluetooth ?? BluetoothPlatform(),
        _injectedEngine = engine {
    _peers = PeersDao(db);
    _syncState = SyncStateDao(db);
  }

  /// 生产默认传输：局域网 mDNS + TCP。
  static Transport _defaultTransportFactory(String deviceId, String deviceName) =>
      LanTransport(deviceId: deviceId, deviceName: deviceName);

  final AppDatabase db;
  final IdentityKeys identity;
  final ImageFileStore imageFiles;
  final SyncTransportFactory _transportFactory;
  final MulticastLock _multicastLock;
  final PermissionRequester _permissions;
  final BluetoothChannel _bluetooth;
  final SyncEngine? _injectedEngine;

  /// 引擎配置（设备昵称在 [start] 时按当前值覆盖）。
  final SyncEngineOptions engineOptions;

  late final PeersDao _peers;
  late final SyncStateDao _syncState;

  SyncEngine? _engine;
  Transport? _transport;
  StreamSubscription<SyncEvent>? _eventSub;
  StreamSubscription<PairingChallenge>? _challengeSub;
  final List<StreamSubscription<Object?>> _transportSubs = [];

  String _deviceName = '';
  bool _autoConnect = true;
  bool _running = false;
  bool _started = false;
  bool _bluetoothScanning = false;
  bool _disposed = false;
  String? _lastError;
  PairingChallenge? _pendingChallenge;
  ({String deviceId, String identityPublicKey})? _qrExpectation;

  final Map<String, PeerDiscovered> _discovered = {};
  final Map<String, SyncSession> _sessionsByPeer = {};
  final Set<String> _connecting = {};
  final Set<SyncSession> _knownSessions = {};
  final List<SyncEvent> _recentEvents = [];
  final StreamController<List<PeerRow>> _peersStream =
      StreamController<List<PeerRow>>.broadcast();
  List<PeerRow> _lastPeers = const [];

  SyncEngine get engine {
    final value = _engine;
    if (value == null) {
      throw StateError('同步服务尚未启动');
    }
    return value;
  }

  // ---------- 对外状态 ----------

  bool get running => _running;
  bool get autoConnect => _autoConnect;
  String get deviceName => _deviceName;
  bool get bluetoothScanning => _bluetoothScanning;
  String? get lastError => _lastError;
  PairingChallenge? get pendingChallenge => _pendingChallenge;
  List<SyncEvent> get recentEvents => List.unmodifiable(_recentEvents);
  List<PeerDiscovered> get discoveredPeers => List.unmodifiable(_discovered.values);
  /// 本机 TCP 监听端口（LanTransport 启动后有效；手动直连时需要告诉对方）。
  int? get listenPort {
    final transport = _transport;
    return transport is LanTransport ? transport.port : null;
  }

  /// 本机二维码配对文本（设备 ID + 昵称 + 身份公钥）。
  String get qrPayload => PairQrCodec.encode(
        PairQrData(
          deviceId: identity.deviceId,
          name: _deviceName,
          identityPublicKey: identity.publicKeyBase64,
        ),
      );

  /// 已配对设备白名单的响应式流：每个订阅者先收到当前快照，再收到后续更新
  /// （广播流不重放旧事件，晚订阅者需要初始值）。
  ///
  /// 白名单只在配对/解除配对/启动时变化，因此由事件驱动刷新而非 drift
  /// watch 流（避免 flutter_test 假异步区内 watch 流阻塞后续查询）。
  Stream<List<PeerRow>> watchPeers() {
    final controller = StreamController<List<PeerRow>>();
    controller.add(_lastPeers);
    final sub = _peersStream.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = sub.cancel;
    return controller.stream;
  }

  bool isConnecting(String peerId) => _connecting.contains(peerId);
  bool isConnected(String peerId) => _sessionsByPeer.containsKey(peerId);

  // ---------- 生命周期 ----------

  /// 启动同步：加载昵称/开关 → 建引擎 → 请求权限 → 组播锁 → 启动传输。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      _deviceName = await _syncState.get('device_name') ?? '我的设备';
      _autoConnect = await _syncState.getBool('auto_connect', fallback: true);
      _engine = _injectedEngine ??
          SyncEngine(
            storage: DriftSyncStorage(db),
            identity: identity,
            imageFiles: imageFiles,
            options: _optionsWithName(_deviceName),
          );
      _listenEngine();
      unawaited(_emitPeers());

      await _requestRuntimePermissions();
      await _multicastLock.acquire();

      final transport = _transportFactory(identity.deviceId, _deviceName);
      _transport = transport;
      await transport.start();
      _listenTransport(transport);

      _running = true;
      notifyListeners();
    } catch (e) {
      _lastError = '启动同步失败：$e';
      _running = false;
      _started = false;
      notifyListeners();
    }
  }

  /// 停止同步（App 退出/重启传输时调用）。
  Future<void> stop() async {
    _started = false;
    await _stopInternal();
  }

  /// 重启传输（昵称变更后应用新名称，重新发现并自动连接）。
  Future<void> restart() async {
    _started = false;
    await _stopInternal();
    await start();
  }

  Future<void> _stopInternal() async {
    await _challengeSub?.cancel();
    await _eventSub?.cancel();
    _challengeSub = null;
    _eventSub = null;
    for (final sub in _transportSubs) {
      await sub.cancel();
    }
    _transportSubs.clear();

    await _engine?.closeAll();
    await _transport?.stop();
    _transport = null;
    _engine = null;
    await _multicastLock.release();

    _sessionsByPeer.clear();
    _connecting.clear();
    _knownSessions.clear();
    _discovered.clear();
    _pendingChallenge = null;
    _recentEvents.clear();
    _bluetoothScanning = false;
    unawaited(_emitPeers());
    _running = false;
    notifyListeners();
  }

  SyncEngineOptions _optionsWithName(String name) => SyncEngineOptions(
        appVersion: engineOptions.appVersion,
        protocolVersion: engineOptions.protocolVersion,
        deviceName: name,
        chunkSize: engineOptions.chunkSize,
        handshakeTimeout: engineOptions.handshakeTimeout,
        maxFramePayloadLength: engineOptions.maxFramePayloadLength,
        autoAcceptPairing: engineOptions.autoAcceptPairing,
        maxImageChunksPerSession: engineOptions.maxImageChunksPerSession,
      );

  @override
  void dispose() {
    _disposed = true;
    unawaited(_peersStream.close());
    unawaited(stop());
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // ---------- 用户操作 ----------

  /// 修改本机昵称并重启传输（昵称进入 mDNS TXT 与握手 PeerInfo）。
  Future<void> setDeviceName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _deviceName) return;
    await _syncState.set('device_name', trimmed);
    _deviceName = trimmed;
    if (_started) {
      await restart();
    } else {
      notifyListeners();
    }
  }

  /// 自动连接开关：只影响「发现已配对设备自动连接」；手动操作不受影响。
  Future<void> setAutoConnect(bool enabled) async {
    if (_autoConnect == enabled) return;
    _autoConnect = enabled;
    await _syncState.setBool('auto_connect', enabled);
    notifyListeners();
  }

  /// 确认配对码（SAS）：转发给引擎，唤醒等待中的配对握手。
  Future<void> confirmPairing(String code) async {
    await engine.confirmPairing(code);
    _pendingChallenge = null;
    notifyListeners();
  }

  /// 关闭配对确认浮层（引擎仍在等待；连接超时会自动关闭）。
  void dismissPairingChallenge() {
    _pendingChallenge = null;
    notifyListeners();
  }

  /// 通过二维码锁定对端身份；发现该设备后自动连接并进入配对。
  Future<void> prepareQrPairing(PairQrData data) async {
    _qrExpectation = (
      deviceId: data.deviceId,
      identityPublicKey: data.identityPublicKey,
    );
    engine.prepareQrPairing(data.deviceId, data.identityPublicKey);
    notifyListeners();
    if (_discovered.containsKey(data.deviceId)) {
      await _maybeAutoConnect(data.deviceId, force: true);
    }
  }

  /// 手动连接发现的设备（配对按钮；未配对也允许发起）。
  Future<void> connectToDiscovered(String peerId) {
    return _maybeAutoConnect(peerId, force: true);
  }

  /// 手动兜底：输入对端 IP 直连（跳过发现）。
  Future<void> connectToHost(String host, int port) async {
    final transport = _transport;
    if (transport == null || !_running) {
      _lastError = '同步服务尚未启动，请稍后再试';
      notifyListeners();
      return;
    }
    try {
      final conn = await transport.connectToHost(host, port);
      final session = await engine.connect(conn);
      await _registerSession(session);
    } catch (e) {
      _lastError = '手动连接失败：$e';
      notifyListeners();
    }
  }

  /// 解除配对：从白名单移除并关闭与对方的活动会话。
  Future<void> unpair(String peerId) async {
    await _peers.remove(peerId);
    final session = _sessionsByPeer.remove(peerId);
    if (session != null) {
      await session.close();
    }
    unawaited(_emitPeers());
    notifyListeners();
  }

  /// 蓝牙扫描入口（docs/02 §3.3 预留；原生实现前提示待真机联调）。
  Future<void> startBluetoothScan() async {
    try {
      if (!await _bluetooth.isAvailable) {
        _lastError = '蓝牙通道未就绪（待真机联调接入）';
        notifyListeners();
        return;
      }
      await _bluetooth.startScan(
        deviceId: identity.deviceId,
        deviceName: _deviceName,
      );
      _bluetoothScanning = true;
      notifyListeners();
    } on PlatformException catch (e) {
      _lastError = '蓝牙扫描不可用：${e.code}（待真机联调）';
      notifyListeners();
    } on MissingPluginException {
      _lastError = '蓝牙通道未就绪（待真机联调接入）';
      notifyListeners();
    }
  }

  /// 停止蓝牙扫描。
  Future<void> stopBluetoothScan() async {
    try {
      await _bluetooth.stopScan();
    } on PlatformException {
      // 原生未实现时忽略。
    } on MissingPluginException {
      // 原生未实现时忽略。
    }
    _bluetoothScanning = false;
    notifyListeners();
  }

  /// 手动连接蓝牙设备（原生实现后可用；当前抛 not_implemented）。
  Future<void> connectBluetooth(String peerId) async {
    try {
      final conn = await _bluetooth.connect(peerId);
      final session = await engine.connect(conn);
      await _registerSession(session, expectedPeerId: peerId);
    } on PlatformException catch (e) {
      _lastError = '蓝牙连接不可用：${e.code}（待真机联调）';
      notifyListeners();
    } on MissingPluginException {
      _lastError = '蓝牙连接不可用（待真机联调）';
      notifyListeners();
    }
  }

  // ---------- 内部编排 ----------

  void _listenEngine() {
    _eventSub = engine.events.listen(_onEngineEvent);
    _challengeSub = engine.onPairingChallenge.listen(_onChallenge);
  }

  void _listenTransport(Transport transport) {
    _transportSubs.add(transport.onPeerDiscovered.listen(
      (peer) => _onDiscovered(peer, autoConnect: true),
    ));
    _transportSubs.add(transport.onIncoming.listen((conn) {
      unawaited(_registerIncoming(conn));
    }));
    _transportSubs.add(
      _bluetooth.onPeerDiscovered.listen(
        (peer) => _onDiscovered(peer, autoConnect: false),
      ),
    );
  }

  void _onDiscovered(PeerDiscovered peer, {required bool autoConnect}) {
    if (peer.peerId == identity.deviceId) return;
    _discovered[peer.peerId] = peer;
    notifyListeners();
    if (autoConnect) {
      unawaited(_maybeAutoConnect(peer.peerId));
    }
  }

  Future<void> _maybeAutoConnect(String peerId, {bool force = false}) async {
    if (peerId == identity.deviceId) return;
    if (_connecting.contains(peerId) || _sessionsByPeer.containsKey(peerId)) {
      return;
    }
    final transport = _transport;
    if (transport == null || !_running) return;

    final isQrTarget = _qrExpectation?.deviceId == peerId;
    // 自动连接关闭时直接跳过，避免无谓的白名单查询。
    if (!force && !isQrTarget && !_autoConnect) return;
    final paired = await _peers.isPaired(peerId);
    if (!force && !isQrTarget && !paired) return;

    _connecting.add(peerId);
    notifyListeners();
    try {
      final conn = await transport.connect(peerId);
      final session = await engine.connect(conn);
      await _registerSession(session, expectedPeerId: peerId);
    } catch (e) {
      _lastError = '连接 ${_nameOf(peerId)} 失败：$e';
      notifyListeners();
    } finally {
      _connecting.remove(peerId);
      notifyListeners();
    }
  }

  Future<void> _registerIncoming(Connection conn) async {
    try {
      final session = await engine.accept(conn);
      await _registerSession(session);
    } catch (e) {
      _lastError = '接受连接失败：$e';
      notifyListeners();
    }
  }

  /// 会话去重：握手识别出对端后，同端已有活跃会话则关闭新会话。
  Future<void> _registerSession(
    SyncSession session, {
    String? expectedPeerId,
  }) async {
    _knownSessions.add(session);
    // 握手可能失败关闭（peerKnown 永不完成），等 done 先到则放弃。
    await Future.any([session.peerKnown, session.done]);
    final peerId = session.peerDeviceId;
    if (peerId == null || peerId == identity.deviceId) {
      _knownSessions.remove(session);
      return;
    }
    final existing = _sessionsByPeer[peerId];
    if (existing != null && !identical(existing, session)) {
      // 双方同时发起连接时可能出现重复会话：保留先建立的，关闭新会话。
      await session.close();
      _knownSessions.remove(session);
      return;
    }
    _sessionsByPeer[peerId] = session;
    notifyListeners();
    unawaited(session.done.then((_) {
      if (identical(_sessionsByPeer[peerId], session)) {
        _sessionsByPeer.remove(peerId);
      }
      _knownSessions.remove(session);
      notifyListeners();
    }));
  }

  void _onChallenge(PairingChallenge challenge) {
    _pendingChallenge = challenge;
    notifyListeners();
  }

  void _onEngineEvent(SyncEvent event) {
    _recentEvents.add(event);
    if (_recentEvents.length > 20) {
      _recentEvents.removeAt(0);
    }
    if (event.kind == SyncEventKind.paired) {
      // 配对成功后刷新白名单流（UI 设备卡片消费）。
      unawaited(_emitPeers());
    }
    if (event.kind == SyncEventKind.error) {
      _lastError = event.message;
    }
    notifyListeners();
  }

  Future<void> _emitPeers() async {
    if (_peersStream.isClosed) return;
    try {
      final peers = await _peers.list();
      _lastPeers = peers;
      if (!_peersStream.isClosed) {
        _peersStream.add(peers);
      }
    } catch (_) {
      // 白名单读取失败不阻塞同步。
    }
  }

  Future<void> _requestRuntimePermissions() async {
    if (!Platform.isAndroid) return;
    try {
      await _permissions.request(const [
        'android.permission.NEARBY_WIFI_DEVICES',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.BLUETOOTH_SCAN',
        'android.permission.BLUETOOTH_CONNECT',
      ]);
    } catch (_) {
      // 权限请求失败不阻塞同步；部分环境仍可通过手动直连使用。
    }
  }

  String _nameOf(String peerId) =>
      _discovered[peerId]?.name?.isNotEmpty == true
          ? _discovered[peerId]!.name!
          : peerId;
}
