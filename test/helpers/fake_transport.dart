import 'dart:async';

import 'package:couple_space/core/sync/transports/transport.dart';

import 'memory_connection.dart';

/// 测试用假传输：不碰真实网络。
///
/// - 发现事件由测试手动 [emitDiscovery] / [emitIncoming] 注入；
/// - [connect] / [connectToHost] 默认返回 [MemoryDuplex] 的一端，
///   也可通过回调让测试拿到另一端（喂给对端引擎）。
class FakeTransport implements Transport {
  FakeTransport({this.onConnect, this.onConnectHost});

  /// 发起连接时创建双工连接；返回的 duplex 对端由测试转交对方引擎。
  Future<MemoryDuplex> Function(String peerId)? onConnect;
  Future<MemoryDuplex> Function(String host, int port)? onConnectHost;

  final StreamController<PeerDiscovered> _discovered =
      StreamController<PeerDiscovered>.broadcast();
  final StreamController<Connection> _incoming =
      StreamController<Connection>.broadcast();
  final List<String> connectedPeerIds = [];
  final List<(String, int)> connectedHosts = [];

  @override
  TransportKind get kind => TransportKind.lan;

  @override
  Stream<PeerDiscovered> get onPeerDiscovered => _discovered.stream;

  @override
  Stream<Connection> get onIncoming => _incoming.stream;

  void emitDiscovery(PeerDiscovered peer) {
    _discovered.add(peer);
  }

  void emitIncoming(Connection conn) {
    _incoming.add(conn);
  }

  @override
  Future<void> start({int listenPort = 0}) async {}

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> stop() async {
    await close();
  }

  @override
  Future<Connection> connect(String peerId) async {
    connectedPeerIds.add(peerId);
    final duplex = onConnect != null ? await onConnect!(peerId) : MemoryDuplex.pair();
    return duplex.a;
  }

  @override
  Future<Connection> connectToHost(String host, int port) async {
    connectedHosts.add((host, port));
    final duplex =
        onConnectHost != null ? await onConnectHost!(host, port) : MemoryDuplex.pair();
    return duplex.a;
  }

  Future<void> close() async {
    await _discovered.close();
    await _incoming.close();
  }
}
