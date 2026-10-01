import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import '../transport.dart';
import 'mdns_responder.dart';
import 'tcp_connection.dart';

/// 局域网 / 热点传输（mDNS 发现 + TCP 可靠字节流）。
///
/// 覆盖同 WiFi 自动发现与热点手动加入两种场景；蓝牙由平台原生实现并
/// 接入同一 [Transport] 抽象。热点场景同处一个局域网，直接复用本类。
///
/// 发现只负责“上报候选设备”；是否自动连接由上层按 peers 白名单决定
/// （docs/02 §5：自动连接仅对已配对设备生效）。
class LanTransport implements Transport {
  LanTransport({
    required this.deviceId,
    required this.deviceName,
    this.serviceType = defaultServiceType,
    this.discoveryInterval = const Duration(seconds: 5),
    this.mdnsPort = 5353,
  });

  static const String defaultServiceType = '_couple-space._tcp';

  final String deviceId;
  final String deviceName;
  final String serviceType;
  final Duration discoveryInterval;

  /// mDNS 端口。标准为 5353；测试/调试可改端口以避开本机其它占用。
  final int mdnsPort;

  final StreamController<PeerDiscovered> _discovered =
      StreamController<PeerDiscovered>.broadcast();
  final StreamController<Connection> _incoming =
      StreamController<Connection>.broadcast();
  final Map<String, _PeerEndpoint> _endpoints = {};

  ServerSocket? _serverSocket;
  MDnsClient? _mdns;
  MdnsResponder? _responder;
  bool _running = false;

  @override
  TransportKind get kind => TransportKind.lan;

  @override
  Stream<PeerDiscovered> get onPeerDiscovered => _discovered.stream;

  @override
  Stream<Connection> get onIncoming => _incoming.stream;

  /// 监听端口（启动后有效）。
  int? get port => _serverSocket?.port;

  bool get isRunning => _running;

  /// 启动传输：绑定 TCP 监听、注册 mDNS 服务、开始周期发现。
  Future<void> start({int listenPort = 0}) async {
    if (_running) return;

    final server = await ServerSocket.bind(InternetAddress.anyIPv4, listenPort);
    server.listen((socket) {
      _incoming.add(TcpConnection(socket));
    });
    _serverSocket = server;

    final responder = MdnsResponder(
      serviceType: serviceType,
      instanceName: '$deviceId.$serviceType.local.',
      hostName: '$deviceId.local.',
      port: server.port,
      txtEntries: ['id=$deviceId', 'name=$deviceName', 'pv=1'],
      listenPort: mdnsPort,
    );
    _responder = responder;
    await responder.start();

    _startDiscovery();
    _running = true;
  }

  @override
  Future<void> startDiscovery() async {
    if (_mdns != null) return;
    await _startDiscovery();
  }

  Future<void> _startDiscovery() async {
    final mdns = MDnsClient();
    _mdns = mdns;
    try {
      await mdns.start(
        interfacesFactory: _multicastCapableInterfaces,
        mDnsPort: mdnsPort,
        // Windows 组播发送会触发异步 socket 错误（errno 1232），忽略。
        onError: (Object e) {},
      );
    } catch (_) {
      // 个别平台（如 Windows 的 reusePort 提示）可能打印警告但不影响。
    }
    _discoveryLoop(mdns);
  }

  /// 返回支持加入组播的网卡。
  ///
  /// multicast_dns 会对每个网卡调用 joinMulticast；Windows 上个别虚拟/
  /// 隧道网卡会抛错（errno 10042）导致整个客户端启动失败；且多网卡 join 后
  /// 组播发送可能失效（errno 1232）。这里探测后只返回一个首选网卡。
  static Future<Iterable<NetworkInterface>> _multicastCapableInterfaces(
    InternetAddressType type,
  ) async {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: true,
      type: type,
      includeLoopback: true,
    );
    final result = <NetworkInterface>[];
    final group = type == InternetAddressType.IPv6
        ? InternetAddress('FF02::FB')
        : InternetAddress('224.0.0.251');
    final preferred = interfaces.where((i) =>
        i.addresses.isNotEmpty &&
        !i.addresses.first.address.startsWith('127.') &&
        !i.addresses.first.address.startsWith('169.254.'));
    for (final iface in [...preferred, ...interfaces]) {
      final probe = await RawDatagramSocket.bind(
        type == InternetAddressType.IPv6
            ? InternetAddress.anyIPv6
            : InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
        ttl: 255,
      );
      try {
        probe.joinMulticast(group, iface);
        result.add(iface);
        // 只保留一个可用网卡，保证组播发送不失效。
        break;
      } catch (_) {
        // 该网卡不支持组播加入，跳过。
      } finally {
        probe.close();
      }
    }
    return result;
  }

  /// 周期发现循环：避免多轮查询重叠。
  Future<void> _discoveryLoop(MDnsClient mdns) async {
    while (_running && _mdns == mdns) {
      await _discoverOnce(mdns);
      if (!_running || _mdns != mdns) return;
      await Future<void>.delayed(discoveryInterval);
    }
  }

  Future<void> _discoverOnce(MDnsClient mdns) async {
    // multicast_dns 在匹配响应时会去掉末尾点，因此查询名不带点。
    final serviceName = '$serviceType.local';
    try {
      final ptrs = await mdns
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceName),
            timeout: discoveryInterval,
          )
          .toList();
      for (final ptr in ptrs) {
        final instance = ptr.domainName;
        final id = _peerIdFromInstance(instance);
        if (id == null || id == deviceId) continue;
        await _resolvePeer(mdns, id, instance);
      }
    } catch (_) {
      // 发现失败不影响运行，下一轮重试。
    }
  }

  Future<void> _resolvePeer(MDnsClient mdns, String id, String instance) async {
    final endpoint = _endpoints[id];
    if (endpoint != null) return;

    SrvResourceRecord? srv;
    IPAddressResourceRecord? address;
    TxtResourceRecord? txt;
    try {
      srv = await mdns
          .lookup<SrvResourceRecord>(
            ResourceRecordQuery.service(instance),
            timeout: discoveryInterval,
          )
          .first;
      final results = await Future.wait([
        mdns
            .lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv4(srv.target),
              timeout: discoveryInterval,
            )
            .first,
        mdns
            .lookup<TxtResourceRecord>(
              ResourceRecordQuery.text(instance),
              timeout: discoveryInterval,
            )
            .first,
      ]);
      address = results[0] as IPAddressResourceRecord;
      txt = results[1] as TxtResourceRecord;
    } catch (_) {
      return;
    }

    _endpoints[id] = _PeerEndpoint(
      id: id,
      name: _nameFromTxt(txt.text),
      host: address.address.address,
      port: srv.port,
    );
    _discovered.add(PeerDiscovered(peerId: id, name: _nameFromTxt(txt.text)));
  }

  /// 通过手动输入的 IP 直连（跳过发现），仍走同一 TCP 通道。
  Future<Connection> connectToHost(String host, int port) async {
    final socket = await Socket.connect(host, port);
    return TcpConnection(socket);
  }

  @override
  Future<Connection> connect(String peerId) async {
    final endpoint = _endpoints[peerId];
    if (endpoint == null) {
      throw StateError('尚未发现设备 $peerId，请先完成发现或手动直连');
    }
    return connectToHost(endpoint.host, endpoint.port);
  }

  @override
  Future<void> stopDiscovery() async {
    _mdns?.stop();
    _mdns = null;
  }

  Future<void> stop() async {
    await stopDiscovery();
    _running = false;
    await _responder?.stop();
    _responder = null;
    await _serverSocket?.close();
    _serverSocket = null;
  }

  static String? _peerIdFromInstance(String instance) {
    final first = instance.split('.').first;
    return first.isEmpty ? null : first;
  }

  static String? _nameFromTxt(String text) {
    for (final line in text.split('\n')) {
      if (line.startsWith('name=')) {
        final value = line.substring('name='.length).trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }
}

class _PeerEndpoint {
  const _PeerEndpoint({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });

  final String id;
  final String? name;
  final String host;
  final int port;
}
