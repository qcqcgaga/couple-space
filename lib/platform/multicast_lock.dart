import 'package:flutter/services.dart';

/// WiFi 组播锁：Android 侧扫描/接收 mDNS 组播包需要持有
/// `WifiManager.MulticastLock`（docs/02 §3.2），否则收不到响应。
abstract interface class MulticastLock {
  Future<void> acquire();

  Future<void> release();
}

/// 平台通道实现：调用 Android 原生侧 `couple_space/wifi` 通道
/// （MainActivity 用 WifiManager 维护引用计数锁）。
///
/// 非 Android 平台原生侧未实现时会收到 `not_implemented`，这里静默忽略，
/// 不影响 Windows 测试与 iOS（iOS 不需要 MulticastLock）。
class MethodChannelMulticastLock implements MulticastLock {
  MethodChannelMulticastLock({
    this.channel = const MethodChannel('couple_space/wifi'),
  });

  final MethodChannel channel;

  @override
  Future<void> acquire() async {
    try {
      await channel.invokeMethod<void>('acquireMulticastLock');
    } on PlatformException catch (e) {
      if (e.code != 'not_implemented') rethrow;
    }
  }

  @override
  Future<void> release() async {
    try {
      await channel.invokeMethod<void>('releaseMulticastLock');
    } on PlatformException catch (e) {
      if (e.code != 'not_implemented') rethrow;
    }
  }
}

/// 无操作实现（测试与不需要组播锁的平台）。
class NoopMulticastLock implements MulticastLock {
  const NoopMulticastLock();

  @override
  Future<void> acquire() async {}

  @override
  Future<void> release() async {}
}
