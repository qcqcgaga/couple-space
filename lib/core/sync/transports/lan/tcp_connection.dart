import 'dart:io';

import '../transport.dart';

/// 基于 dart:io [Socket] 的可靠字节流连接。
///
/// 注意：底层 Socket 流是单订阅流，由上层 FrameChannel / 加密通道独占监听。
class TcpConnection implements Connection {
  TcpConnection(this._socket);

  final Socket _socket;

  @override
  Stream<List<int>> get incoming => _socket;

  @override
  Future<void> send(List<int> bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}
