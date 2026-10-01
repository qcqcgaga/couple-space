import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// 纯 Dart mDNS 应答器（服务注册）。
///
/// `multicast_dns` 包只支持发现（查询），不支持发布；而 docs/02 §3.2 要求
/// 应用内注册 `_couple-space._tcp` 服务。这里实现一个最小的 mDNS 应答器：
/// 监听 224.0.0.251:5353，回应 PTR / SRV / TXT / A 查询，并周期性发送
/// 主动宣告（announcement），让已配对设备在局域网内可被发现。
///
/// 实现仅覆盖本项目需要的记录类型；跨平台纯 Dart，可在 Windows 单测。
class MdnsResponder {
  MdnsResponder({
    required this.serviceType,
    required this.instanceName,
    required this.hostName,
    required this.port,
    required this.txtEntries,
    this.multicastGroup = '224.0.0.251',
    this.listenPort = 5353,
    this.announceInterval = const Duration(seconds: 30),
  });

  /// 服务类型，如 `_couple-space._tcp`。
  final String serviceType;

  /// 实例名，如 `deviceId._couple-space._tcp.local.`。
  final String instanceName;

  /// 主机名，如 `deviceId.local.`。
  final String hostName;

  /// 对外公布的 TCP 端口。
  final int port;

  /// TXT 记录（key=value 列表）。
  final List<String> txtEntries;

  final String multicastGroup;
  final int listenPort;
  final Duration announceInterval;

  RawDatagramSocket? _socket;
  Timer? _announceTimer;
  bool _running = false;

  String get serviceName => '$serviceType.local.';

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      listenPort,
      reuseAddress: true,
      ttl: 255,
    );
    await _joinMulticast(socket, InternetAddress(multicastGroup));
    socket.listen(
      (event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        _onQuery(datagram);
      },
      // Windows 上组播发送可能触发异步 socket 错误（errno 1232），
      // 属环境噪声，忽略以免变成未处理异常。
      onError: (Object e, StackTrace s) {},
    );
    _socket = socket;
    _running = true;

    // 启动即宣告一次，加快发现；之后周期性刷新（标准 mDNS 行为）。
    await _announce();
    _announceTimer = Timer.periodic(announceInterval, (_) {
      _announce();
    });
  }

  Future<void> stop() async {
    _announceTimer?.cancel();
    _announceTimer = null;
    _running = false;
    _socket?.close();
    _socket = null;
  }

  Future<void> _onQuery(Datagram datagram) async {
    final localAddress = await _localIpFor(datagram.address);
    final response = buildResponse(
      datagram.data,
      localAddress: localAddress,
    );
    if (response == null) return;
    // 组播应答：查询方已加入组播组即可收到；避免单机回环下
    // 单播到特定网卡 IP 投递不到的问题。
    _socket?.send(response, InternetAddress(multicastGroup), listenPort);
  }

  Future<void> _announce() async {
    final socket = _socket;
    if (socket == null) return;
    final localAddress = await _localIpFor(null);
    socket.send(
      buildAnnouncement(localAddress: localAddress),
      InternetAddress(multicastGroup),
      listenPort,
    );
  }

  /// 处理一条查询，返回应答字节；与本服务无关的查询返回 null。
  ///
  /// [localAddress] 为应答中 A 记录使用的本机 IPv4 地址（测试可注入）。
  Uint8List? buildResponse(
    List<int> query, {
    required Uint8List localAddress,
  }) {
    final Uint8List bytes;
    if (query is Uint8List) {
      bytes = query;
    } else {
      bytes = Uint8List.fromList(query);
    }
    if (bytes.length < 12) return null;

    final questions = <_DnsQuestion>[];
    var offset = 12;
    final qdCount = ByteData.sublistView(bytes).getUint16(4);
    for (var i = 0; i < qdCount; i++) {
      final name = _readName(bytes, offset);
      if (name == null) return null;
      offset = name.$2;
      if (offset + 4 > bytes.length) return null;
      final type = ByteData.sublistView(bytes, offset).getUint16(0);
      final clazz = ByteData.sublistView(bytes, offset).getUint16(2);
      offset += 4;
      questions.add(_DnsQuestion(name.$1, type, clazz));
    }

    final answers = <_DnsRecord>[];
    for (final q in questions) {
      if (q.clazz != 1 && q.clazz != 255) continue; // 仅 IN
      final lower = _trimDot(q.name).toLowerCase();
      if (q.type == 255 || q.type == 12) {
        if (lower == _trimDot(serviceName).toLowerCase()) {
          answers.addAll(_serviceRecords(localAddress));
        }
      }
      if (q.type == 255 || q.type == 33) {
        if (lower == _trimDot(instanceName).toLowerCase()) {
          answers.add(_srvRecord());
          answers.add(_aRecord(localAddress));
        }
      }
      if (q.type == 255 || q.type == 16) {
        if (lower == _trimDot(instanceName).toLowerCase()) {
          answers.add(_txtRecord());
        }
      }
      if (q.type == 255 || q.type == 1) {
        if (lower == _trimDot(hostName).toLowerCase()) {
          answers.add(_aRecord(localAddress));
        }
      }
    }
    if (answers.isEmpty) return null;
    return _encodeResponse(
      id: ByteData.sublistView(bytes).getUint16(0),
      answers: answers,
    );
  }

  /// 主动宣告（无问题区）。
  Uint8List buildAnnouncement({required Uint8List localAddress}) {
    return _encodeResponse(
      id: 0,
      answers: _serviceRecords(localAddress),
    );
  }

  List<_DnsRecord> _serviceRecords(Uint8List localAddress) => [
        _ptrRecord(),
        _srvRecord(),
        _txtRecord(),
        _aRecord(localAddress),
      ];

  _DnsRecord _ptrRecord() => _DnsRecord(
        serviceName,
        type: 12,
        data: _encodeName(instanceName),
      );

  _DnsRecord _srvRecord() {
    final target = _encodeName(hostName);
    final data = Uint8List(6 + target.length);
    final view = ByteData.sublistView(data);
    view.setUint16(0, 0); // priority
    view.setUint16(2, 0); // weight
    view.setUint16(4, port);
    data.setRange(6, data.length, target);
    return _DnsRecord(instanceName, type: 33, data: data);
  }

  _DnsRecord _txtRecord() {
    final parts = <int>[];
    for (final entry in txtEntries) {
      final bytes = utf8.encode(entry);
      parts.add(bytes.length);
      parts.addAll(bytes);
    }
    return _DnsRecord(instanceName, type: 16, data: Uint8List.fromList(parts));
  }

  _DnsRecord _aRecord(Uint8List address) =>
      _DnsRecord(hostName, type: 1, data: address);

  Uint8List _encodeResponse({
    required int id,
    required List<_DnsRecord> answers,
  }) {
    final builder = BytesBuilder(copy: false);
    final header = Uint8List(12);
    final view = ByteData.sublistView(header);
    view.setUint16(0, id);
    view.setUint16(2, 0x8400); // QR=1, AA=1
    // multicast_dns 的解析器不跳过问题区，因此应答不回显问题。
    view.setUint16(4, 0);
    view.setUint16(6, answers.length);
    view.setUint16(8, 0);
    view.setUint16(10, 0);
    builder.add(header);

    for (final answer in answers) {
      builder.add(_encodeName(answer.name));
      final fixed = Uint8List(10);
      final fixedView = ByteData.sublistView(fixed);
      fixedView.setUint16(0, answer.type);
      fixedView.setUint16(2, 1); // class IN
      fixedView.setUint32(4, 120); // TTL
      fixedView.setUint16(8, answer.data.length);
      builder.add(fixed);
      builder.add(answer.data);
    }
    return builder.toBytes();
  }

  /// 本机 IPv4 地址：优先取查询来源所在的网卡，其次任意非回环地址。
  Future<Uint8List> _localIpFor(InternetAddress? sender) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: true,
        includeLinkLocal: true,
      );
      for (final iface in interfaces) {
        if (sender != null && iface.addresses.contains(sender)) {
          return _pickAddress(iface.addresses);
        }
      }
      for (final iface in interfaces) {
        if (iface.addresses.isNotEmpty) return _pickAddress(iface.addresses);
      }
    } catch (_) {
      // 忽略网卡枚举失败，退化为回环。
    }
    return Uint8List.fromList([127, 0, 0, 1]);
  }

  /// 逐网卡加入组播；个别网卡失败（Windows 虚拟/隧道网卡）则跳过，
  /// 只加入一个首选网卡，避免 Windows 上多网卡 join 后组播发送失效。
  Future<void> _joinMulticast(RawDatagramSocket socket, InternetAddress group) async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: true,
        includeLoopback: true,
      );
      final preferred = interfaces.where((i) =>
          i.addresses.isNotEmpty &&
          !i.addresses.first.address.startsWith('127.') &&
          !i.addresses.first.address.startsWith('169.254.'));
      for (final iface in [...preferred, ...interfaces]) {
        try {
          socket.joinMulticast(group, iface);
          return;
        } catch (_) {
          // 该网卡不支持组播加入，跳过。
        }
      }
    } catch (_) {
      // 网卡枚举失败，走默认加入。
    }
    socket.joinMulticast(group);
  }

  Uint8List _pickAddress(List<InternetAddress> addresses) {
    final nonLoopback = addresses
        .where((a) =>
            a.address != '127.0.0.1' &&
            a.address != '0.0.0.0' &&
            !a.address.startsWith('169.254.'))
        .toList();
    final chosen = nonLoopback.isNotEmpty ? nonLoopback.first : addresses.first;
    return Uint8List.fromList(chosen.rawAddress);
  }
}

String _trimDot(String name) => name.endsWith('.') ? name.substring(0, name.length - 1) : name;

class _DnsQuestion {
  const _DnsQuestion(this.name, this.type, this.clazz);

  final String name;
  final int type;
  final int clazz;
}

class _DnsRecord {
  const _DnsRecord(this.name, {required this.type, required this.data});

  final String name;
  final int type;
  final Uint8List data;
}

/// 读取 DNS 名字（支持压缩指针），返回 (名字, 新偏移)。
(String, int)? _readName(Uint8List bytes, int offset) {
  final labels = <String>[];
  var cursor = offset;
  var jumped = false;
  var jumpTarget = 0;
  while (true) {
    if (cursor >= bytes.length) return null;
    final len = bytes[cursor];
    if (len == 0) {
      cursor++;
      break;
    }
    if (len & 0xC0 == 0xC0) {
      if (cursor + 1 >= bytes.length) return null;
      final pointer = ((len & 0x3F) << 8) | bytes[cursor + 1];
      if (!jumped) {
        jumpTarget = cursor + 2;
        jumped = true;
      }
      cursor = pointer;
      continue;
    }
    if (cursor + 1 + len > bytes.length) return null;
    labels.add(String.fromCharCodes(bytes, cursor + 1, cursor + 1 + len));
    cursor += 1 + len;
  }
  final end = jumped ? jumpTarget : cursor;
  return (labels.join('.'), end);
}

Uint8List _encodeName(String name) {
  final normalized = name.endsWith('.') ? name : '$name.';
  final builder = BytesBuilder(copy: false);
  for (final label in normalized.split('.')) {
    if (label.isEmpty) continue;
    final bytes = label.codeUnits;
    builder.addByte(bytes.length);
    builder.add(bytes);
  }
  builder.addByte(0);
  return builder.toBytes();
}
