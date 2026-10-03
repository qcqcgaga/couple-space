import 'dart:async';

import 'package:flutter/services.dart';

import '../core/sync/transports/transport.dart';

/// 蓝牙通道接口：生产用 [BluetoothPlatform]（平台通道），
/// 测试可注入假实现，避免触碰 MethodChannel。
abstract interface class BluetoothChannel {
  Future<bool> get isAvailable;

  Stream<PeerDiscovered> get onPeerDiscovered;

  Future<void> startScan({
    required String deviceId,
    required String deviceName,
  });

  Future<void> stopScan();

  Future<Connection> connect(String peerId);
}

/// 蓝牙平台通道契约（docs/02 §3.3，ADR-031）。
///
/// 原生侧（Android/iOS）当前仅预留通道、尚未实现（真机联调放 M3 后期），
/// 未实现时方法统一抛 `PlatformException(code: 'not_implemented')`。
/// Dart 侧按以下契约封装，原生实现后上层无需改动：
///
/// - `isAvailable` → bool（原生未实现时返回 false）
/// - `startScan` / `stopScan`（参数 deviceId / deviceName）
/// - 原生推送 `onPeerDiscovered`（{peerId, name}）
/// - `connect(peerId)` 建立连接
/// - `writeData({peerId, bytes})` / `closeConnection({peerId})`
/// - 原生推送 `onData({peerId, bytes})` 与 `onClosed({peerId})`
class BluetoothPlatform implements BluetoothChannel {
  BluetoothPlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('couple_space/bluetooth') {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  final MethodChannel _channel;
  final StreamController<PeerDiscovered> _peers =
      StreamController<PeerDiscovered>.broadcast();
  final Map<String, BluetoothConnection> _connections = {};

  @override
  Stream<PeerDiscovered> get onPeerDiscovered => _peers.stream;

  @override
  Future<bool> get isAvailable async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on PlatformException catch (e) {
      if (e.code == 'not_implemented') return false;
      rethrow;
    }
  }

  @override
  Future<void> startScan({
    required String deviceId,
    required String deviceName,
  }) {
    return _channel.invokeMethod<void>('startScan', {
      'deviceId': deviceId,
      'deviceName': deviceName,
    });
  }

  @override
  Future<void> stopScan() {
    return _channel.invokeMethod<void>('stopScan');
  }

  @override
  Future<BluetoothConnection> connect(String peerId) async {
    await _channel.invokeMethod<void>('connect', {'peerId': peerId});
    final conn = BluetoothConnection._(this, peerId);
    _connections[peerId] = conn;
    return conn;
  }

  /// 原生 → Dart 回调入口（通道约定，见类注释）。
  Future<Object?> _handleNativeCall(MethodCall call) async {
    final args = (call.arguments as Map?)?.cast<String, Object?>() ?? const {};
    switch (call.method) {
      case 'onPeerDiscovered':
        final peerId = args['peerId']?.toString();
        if (peerId != null && peerId.isNotEmpty) {
          _peers.add(
            PeerDiscovered(peerId: peerId, name: args['name']?.toString()),
          );
        }
        return null;
      case 'onData':
        final peerId = args['peerId']?.toString();
        final raw = args['bytes'];
        if (peerId != null && raw is List<int>) {
          _connections[peerId]?.feed(Uint8List.fromList(raw));
        }
        return null;
      case 'onClosed':
        final peerId = args['peerId']?.toString();
        if (peerId != null) {
          await _connections.remove(peerId)?.closeLocal();
        }
        return null;
      default:
        throw PlatformException(
          code: 'not_implemented',
          message: '未知蓝牙回调：${call.method}',
        );
    }
  }
}

/// 蓝牙连接的字节流封装：incoming 由原生 `onData` 推送，send/close 走通道。
class BluetoothConnection implements Connection {
  BluetoothConnection._(this._platform, this.peerId);

  final BluetoothPlatform _platform;
  final String peerId;
  final StreamController<List<int>> _incoming = StreamController<List<int>>();
  bool _closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  /// 原生侧推送的字节块入口。
  void feed(List<int> bytes) {
    if (!_closed) {
      _incoming.add(bytes);
    }
  }

  @override
  Future<void> send(List<int> bytes) {
    return _platform._channel.invokeMethod<void>('writeData', {
      'peerId': peerId,
      'bytes': bytes,
    });
  }

  @override
  Future<void> close() async {
    try {
      await _platform._channel.invokeMethod<void>('closeConnection', {
        'peerId': peerId,
      });
    } finally {
      await closeLocal();
    }
  }

  /// 仅关闭本地流（原生 `onClosed` 回调时调用，不再回写通道）。
  Future<void> closeLocal() async {
    if (_closed) return;
    _closed = true;
    await _incoming.close();
  }
}
