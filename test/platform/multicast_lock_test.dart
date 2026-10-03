import 'package:couple_space/platform/multicast_lock.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelMulticastLock', () {
    test('acquire/release 调用 Android 通道', () async {
      final channel = const MethodChannel('couple_space/wifi');
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      final lock = MethodChannelMulticastLock(channel: channel);
      await lock.acquire();
      await lock.release();
      expect(calls, ['acquireMulticastLock', 'releaseMulticastLock']);
    });

    test('原生 not_implemented 时静默忽略（非 Android 平台）', () async {
      final channel = const MethodChannel('couple_space/wifi');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'not_implemented');
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding.instance
          .defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null));

      final lock = MethodChannelMulticastLock(channel: channel);
      await lock.acquire();
      await lock.release();
    });
  });
}
