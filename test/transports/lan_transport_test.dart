import 'dart:async';
import 'dart:io';

import 'package:couple_space/core/sync/protocol/codec.dart';
import 'package:couple_space/core/sync/protocol/frames.dart';
import 'package:couple_space/core/sync/transports/lan/lan_transport.dart';
import 'package:couple_space/core/sync/transports/lan/tcp_connection.dart';
import 'package:couple_space/core/sync/transports/transport.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FrameChannel over 回环 TCP', () {
    test('双向交换协议帧', () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final serverReceived = <SyncFrame>[];
      final serverReady = Completer<FrameChannel>();

      server.listen((socket) async {
        final channel = FrameChannel(TcpConnection(socket));
        channel.frames.listen(serverReceived.add);
        channel.start();
        serverReady.complete(channel);
      });

      final clientSocket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        server.port,
      );
      final clientChannel = FrameChannel(TcpConnection(clientSocket));
      final clientFrames = <SyncFrame>[];
      clientChannel.frames.listen(clientFrames.add);
      clientChannel.start();

      await clientChannel.sendFrame(
        const HelloFrame(
          deviceId: 'deviceA',
          appVersion: '0.1.0',
          protocolVersion: 1,
          identityPublicKey: 'cHVia2V5',
        ),
      );

      final serverChannel = await serverReady.future.timeout(
        const Duration(seconds: 5),
      );
      await _waitUntil(() => serverReceived.isNotEmpty);
      expect(serverReceived, hasLength(1));
      expect((serverReceived.single as HelloFrame).deviceId, 'deviceA');

      await serverChannel.sendFrame(
        const PeerInfoFrame(deviceId: 'deviceB', name: '对方的手机'),
      );
      await _waitUntil(() => clientFrames.isNotEmpty);
      expect(clientFrames, hasLength(1));
      expect((clientFrames.single as PeerInfoFrame).name, '对方的手机');

      await clientChannel.close();
      await serverChannel.close();
      await server.close();
    });
  });

  group('LanTransport TCP 直连', () {
    test('手动直连建立连接并交换 Hello', () async {
      final a = LanTransport(deviceId: 'deviceA', deviceName: '小明的手机');
      await a.start(listenPort: 0);
      addTearDown(a.stop);

      final first = _firstIncoming(a.onIncoming);

      final b = LanTransport(deviceId: 'deviceB', deviceName: '小红的手机');
      final clientConnection = await b.connectToHost('127.0.0.1', a.port!);
      final clientChannel = FrameChannel(clientConnection);
      final clientFrames = <SyncFrame>[];
      clientChannel.frames.listen(clientFrames.add);
      clientChannel.start();

      await clientChannel.sendFrame(
        const HelloFrame(
          deviceId: 'deviceB',
          appVersion: '0.1.0',
          protocolVersion: 1,
          identityPublicKey: 'cHVibGlj',
        ),
      );

      final (serverChannel, firstFrame) =
          await first.timeout(const Duration(seconds: 10));
      expect((firstFrame as HelloFrame).deviceId, 'deviceB');

      await serverChannel.sendFrame(const AckFrame(ok: true));
      await _waitUntil(() => clientFrames.isNotEmpty);
      expect(clientFrames, hasLength(1));
      expect(clientFrames.single, isA<AckFrame>());

      await clientChannel.close();
    });
  });

  group('LanTransport mDNS 发现', () {
    test(
      '双端启动后可发现对方并自动连接交换帧',
      () async {
        final a = LanTransport(
          deviceId: 'deviceA',
          deviceName: '小明的手机',
          discoveryInterval: const Duration(seconds: 2),
          mdnsPort: 55353,
        );
        final b = LanTransport(
          deviceId: 'deviceB',
          deviceName: '小红的手机',
          discoveryInterval: const Duration(seconds: 2),
          mdnsPort: 55353,
        );
        addTearDown(a.stop);
        addTearDown(b.stop);

        final bDiscovered = <PeerDiscovered>[];
        final sub = b.onPeerDiscovered.listen(bDiscovered.add);

        await a.start(listenPort: 0);
        await b.start(listenPort: 0);

        final aPeer = await _waitForPeer(
          b,
          bDiscovered,
          'deviceA',
          timeout: const Duration(seconds: 30),
        );
        expect(aPeer.peerId, 'deviceA');
        expect(aPeer.name, '小明的手机');

        final serverIncoming = _firstIncoming(a.onIncoming);

        final clientConnection = await b.connect('deviceA');
        final clientChannel = FrameChannel(clientConnection);
        final clientFrames = <SyncFrame>[];
        clientChannel.frames.listen(clientFrames.add);
        clientChannel.start();
        await clientChannel.sendFrame(
          const HelloFrame(
            deviceId: 'deviceB',
            appVersion: '0.1.0',
            protocolVersion: 1,
            identityPublicKey: 'cHVibGlj',
          ),
        );

        final (serverChannel, firstFrame) = await serverIncoming.timeout(
          const Duration(seconds: 10),
        );
        expect((firstFrame as HelloFrame).deviceId, 'deviceB');

        await serverChannel.sendFrame(
          const PeerInfoFrame(deviceId: 'deviceA', name: '小明的手机'),
        );
        await _waitUntil(() => clientFrames.isNotEmpty);
        expect(clientFrames, hasLength(1));
        expect((clientFrames.single as PeerInfoFrame).name, '小明的手机');

        await clientChannel.close();
        await serverChannel.close();
        await sub.cancel();
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}

/// 监听 [connections]，返回 (帧通道, 收到的第一帧)。
Future<(FrameChannel, SyncFrame)> _firstIncoming(
  Stream<Connection> connections,
) async {
  final completer = Completer<(FrameChannel, SyncFrame)>();
  late final StreamSubscription<Connection> sub;
  sub = connections.listen((connection) {
    final channel = FrameChannel(connection);
    channel.frames.listen((frame) {
      if (!completer.isCompleted) {
        completer.complete((channel, frame));
      }
    });
    channel.start();
  });
  try {
    return await completer.future;
  } finally {
    await sub.cancel();
  }
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('等待条件超时', timeout);
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

Future<PeerDiscovered> _waitForPeer(
  LanTransport transport,
  List<PeerDiscovered> discovered,
  String peerId, {
  required Duration timeout,
}) async {
  final existing = discovered.where((p) => p.peerId == peerId).toList();
  if (existing.isNotEmpty) return existing.first;
  final completer = Completer<PeerDiscovered>();
  final sub = transport.onPeerDiscovered.listen((peer) {
    if (peer.peerId == peerId && !completer.isCompleted) {
      completer.complete(peer);
    }
  });
  try {
    return await completer.future.timeout(timeout);
  } finally {
    await sub.cancel();
  }
}
