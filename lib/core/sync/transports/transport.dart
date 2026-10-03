// 传输层抽象：同步引擎只依赖本接口，不关心底层通道是局域网（WiFi/热点）
// 还是蓝牙。局域网由 Dart 实现（mDNS + TCP），蓝牙由各平台原生实现
// （平台通道接入），两者在引擎层面共用同一套协议与合并逻辑。

/// 传输通道类型。
enum TransportKind { lan, bluetooth }

/// 发现的候选设备。
class PeerDiscovered {
  const PeerDiscovered({required this.peerId, this.name});

  final String peerId;
  final String? name;
}

/// 一条已建立的可靠连接（字节流语义）。
abstract interface class Connection {
  Stream<List<int>> get incoming;

  Future<void> send(List<int> bytes);

  Future<void> close();
}

/// 传输层需要实现的能力。
abstract interface class Transport {
  TransportKind get kind;

  Stream<PeerDiscovered> get onPeerDiscovered;

  Stream<Connection> get onIncoming;

  /// 启动传输：绑定监听（[listenPort] 为 0 表示系统分配）、注册发现服务
  /// 并开始周期发现。
  Future<void> start({int listenPort = 0});

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  /// 停止传输：关闭监听与发现。
  Future<void> stop();

  Future<Connection> connect(String peerId);

  /// 手动兜底：输入对端 IP 直连（跳过发现，仍走同一通道与同步引擎）。
  ///
  /// 局域网/热点场景由 [LanTransport] 支持；蓝牙等通道不支持时抛
  /// [UnsupportedError]。
  Future<Connection> connectToHost(String host, int port);
}
