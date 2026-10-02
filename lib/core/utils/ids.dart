import 'dart:math';

/// 轻量随机 ID 生成（UUID v4 风格字符串）。
///
/// 用于笔记、图片等记录 ID。不同设备并发创建时依赖随机性避免碰撞，
/// 与 LWW 的「设备 ID 决胜」策略配合使用。
class Ids {
  const Ids._();

  static final Random _random = Random.secure();

  /// 生成形如 `xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx` 的随机 ID。
  static String uuid() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
