import 'dart:async';
import 'dart:io';

/// 组播回环诊断工具：验证本机两个 socket 能否通过 224.0.0.251 互达。
///
/// 背景（ADR-015 / ADR-02x）：Windows 在某些网络状态下，两个 socket 绑定
/// 同一 UDP 端口时只有其中一个能收到组播包，导致 mDNS 单机回环测试不成立；
/// 真实局域网（两台设备各自绑定端口）不受影响。本工具用于快速确认当前
/// 机器是否支持 mDNS 回环，测试层据此自动跳过相关用例。
///
/// 用法：
///   dart run tool/multicast_probe.dart listener [端口]   # 监听组播
///   dart run tool/multicast_probe.dart sender [端口]     # 发组播
///   dart run tool/multicast_probe.dart bind [端口]       # 跨进程同端口绑定等待探测包
///   dart run tool/multicast_probe.dart send [端口]       # 跨进程同端口绑定并发送探测包
Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'listener' : args.first;
  final port = args.length > 1 ? int.parse(args[1]) : 55353;
  switch (mode) {
    case 'listener':
      await _listen(port);
    case 'sender':
      await _send(port);
    case 'bind':
      await _crossBind(port);
    case 'send':
      await _crossSend(port);
    default:
      await _listen(port);
  }
}

Future<void> _listen(int port) async {
  final group = InternetAddress('224.0.0.251');
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
  socket.joinMulticast(group);
  stdout.writeln('listening on $port');
  final received = Completer<void>();
  socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    final datagram = socket.receive();
    if (datagram != null) {
      stdout.writeln(
        'received ${String.fromCharCodes(datagram.data)} '
        'from ${datagram.address.address}',
      );
      if (!received.isCompleted) received.complete();
    }
  });
  await received.future.timeout(const Duration(seconds: 20));
  socket.close();
}

Future<void> _send(int port) async {
  final group = InternetAddress('224.0.0.251');
  final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  socket.joinMulticast(group);
  for (var i = 0; i < 5; i++) {
    socket.send('ping-$i'.codeUnits, group, port);
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  stdout.writeln('sent 5 pings');
  socket.close();
}

/// 跨进程同端口绑定（mDNS 单机测试的接收端角色）。
Future<void> _crossBind(int port) async {
  final group = InternetAddress('224.0.0.251');
  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    port,
    reuseAddress: true,
    ttl: 255,
  );
  socket.joinMulticast(group);
  stdout.writeln('CROSS-READY $port');
  final received = Completer<bool>();
  final sub = socket.listen((event) {
    if (event != RawSocketEvent.read) return;
    if (socket.receive() != null && !received.isCompleted) {
      received.complete(true);
    }
  });
  final ok = await received.future
      .timeout(const Duration(seconds: 8), onTimeout: () => false);
  stdout.writeln(ok ? 'CROSS-RECEIVED' : 'CROSS-TIMEOUT');
  await sub.cancel();
  socket.close();
}

/// 跨进程同端口绑定（mDNS 单机测试的发送端角色）。
Future<void> _crossSend(int port) async {
  final group = InternetAddress('224.0.0.251');
  final socket = await RawDatagramSocket.bind(
    InternetAddress.anyIPv4,
    port,
    reuseAddress: true,
    ttl: 255,
  );
  socket.joinMulticast(group);
  for (var i = 0; i < 3; i++) {
    socket.send('probe'.codeUnits, group, port);
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  stdout.writeln('CROSS-SENT');
  socket.close();
}
