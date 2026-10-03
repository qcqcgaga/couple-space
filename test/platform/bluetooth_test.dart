import 'package:couple_space/core/sync/transports/transport.dart';
import 'package:couple_space/platform/bluetooth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BluetoothPlatform 通道契约（预留）', () {
    late _BluetoothHost host;
    late BluetoothPlatform platform;

    setUp(() {
      host = _BluetoothHost();
      platform = BluetoothPlatform(channel: host.channel);
    });

    tearDown(() => host.reset());

    test('原生未实现时 isAvailable 返回 false', () async {
      expect(await platform.isAvailable, isFalse);
    });

    test('startScan 携带本机信息，stopScan 可调用', () async {
      host.available = true;
      expect(await platform.isAvailable, isTrue);
      await platform.startScan(deviceId: 'dev-a', deviceName: '小明');
      await platform.stopScan();
      expect(host.methodCalls, contains('startScan'));
      expect(host.methodCalls, contains('stopScan'));
      expect(host.startScanArgs, {
        'deviceId': 'dev-a',
        'deviceName': '小明',
      });
    });

    test('原生推送 onPeerDiscovered 事件', () async {
      final discovered = <PeerDiscovered>[];
      final sub = platform.onPeerDiscovered.listen(discovered.add);
      await host.push(MethodCall(
        'onPeerDiscovered',
        {'peerId': 'ble-1', 'name': '小红'},
      ));
      expect(discovered.single.peerId, 'ble-1');
      expect(discovered.single.name, '小红');
      await sub.cancel();
    });

    test('connect 建立连接；send/close 走通道；onData 路由到 incoming', () async {
      host.available = true;
      final conn = await platform.connect('ble-1');
      final received = <List<int>>[];
      final sub = conn.incoming.listen(received.add);

      await conn.send([1, 2, 3]);
      expect(host.lastWrite, {
        'peerId': 'ble-1',
        'bytes': [1, 2, 3],
      });

      await host.push(MethodCall(
        'onData',
        {'peerId': 'ble-1', 'bytes': Uint8List.fromList([4, 5])},
      ));
      expect(received.single, [4, 5]);

      await host.push(MethodCall('onClosed', {'peerId': 'ble-1'}));
      await sub.cancel();
    });
  });
}

/// 模拟原生侧：拦截 Dart→原生调用，并可模拟原生→Dart 回调。
class _BluetoothHost {
  _BluetoothHost() {
    messenger.setMockMethodCallHandler(channel, handler);
  }

  final MethodChannel channel = const MethodChannel('couple_space/bluetooth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  bool? available;
  final List<String> methodCalls = [];
  Map<String, Object?>? startScanArgs;
  Map<String, Object?>? lastWrite;

  Future<Object?> handler(MethodCall call) async {
    methodCalls.add(call.method);
    switch (call.method) {
      case 'isAvailable':
        if (available == null) {
          throw PlatformException(code: 'not_implemented', message: '未实现');
        }
        return available;
      case 'startScan':
        startScanArgs = (call.arguments as Map).cast<String, Object?>();
        return null;
      case 'stopScan':
        return null;
      case 'connect':
        return null;
      case 'writeData':
        lastWrite = (call.arguments as Map).cast<String, Object?>();
        return null;
      case 'closeConnection':
        return null;
      default:
        throw PlatformException(code: 'not_implemented');
    }
  }

  /// 模拟原生侧向 Dart 推送消息。
  Future<void> push(MethodCall call) async {
    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(call),
      (_) {},
    );
  }

  void reset() {
    messenger.setMockMethodCallHandler(channel, null);
  }
}
