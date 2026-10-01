import 'dart:async';
import 'dart:typed_data';

import 'package:couple_space/core/sync/transports/transport.dart';

/// 内存双工连接：用于加密通道 / 协议帧的单元测试。
///
/// `A.send(bytes)` 会原样投递给 `B.incoming`（反之亦然），
/// 同时各自记录发出的原始字节，便于断言密文/帧格式。
class MemoryDuplex {
  MemoryDuplex._(this.a, this.b);

  final MemoryConnection a;
  final MemoryConnection b;

  factory MemoryDuplex.pair() {
    final aController = StreamController<List<int>>();
    final bController = StreamController<List<int>>();
    final a = MemoryConnection._(aController);
    final b = MemoryConnection._(bController);
    a._peer = b;
    b._peer = a;
    return MemoryDuplex._(a, b);
  }
}

class MemoryConnection implements Connection {
  MemoryConnection._(this._incoming);

  final StreamController<List<int>> _incoming;
  late MemoryConnection _peer;
  final BytesBuilder sent = BytesBuilder(copy: false);
  bool _closed = false;

  @override
  Stream<List<int>> get incoming => _incoming.stream;

  /// 发出的全部字节（拼接）。
  Uint8List get sentBytes => sent.toBytes();

  @override
  Future<void> send(List<int> bytes) async {
    sent.add(bytes);
    if (!_peer._closed) {
      _peer._incoming.add(bytes);
    }
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _incoming.close();
    await _peer._incoming.close();
    _peer._closed = true;
  }

  /// 测试辅助：直接向本端注入字节（模拟被篡改/重放的入站数据）。
  void inject(List<int> bytes) {
    if (!_closed) {
      _incoming.add(bytes);
    }
  }
}
