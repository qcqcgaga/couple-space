import 'package:flutter/services.dart';

/// 运行时权限请求抽象：同步启动时按平台申请网络/蓝牙相关权限
/// （docs/02 §6：NEARBY_WIFI_DEVICES、位置、蓝牙等）。
abstract interface class PermissionRequester {
  /// 请求一组权限，返回本次实际被授予的权限名集合。
  Future<List<String>> request(List<String> permissions);
}

/// 平台通道实现：调用 Android 原生侧 `couple_space/permissions` 通道
/// （MainActivity 用 ActivityCompat.requestPermissions + 回调补全）。
class ChannelPermissionRequester implements PermissionRequester {
  ChannelPermissionRequester({
    this.channel = const MethodChannel('couple_space/permissions'),
  });

  final MethodChannel channel;

  @override
  Future<List<String>> request(List<String> permissions) async {
    if (permissions.isEmpty) return const [];
    try {
      final result = await channel.invokeMethod<List<Object?>>(
        'request',
        {'permissions': permissions},
      );
      return [for (final item in result ?? const <Object?>[]) item.toString()];
    } on PlatformException catch (e) {
      // iOS / Windows / 测试环境未实现该通道：权限由系统弹窗或平台自行处理。
      if (e.code == 'not_implemented' || e.code == 'unsupported') {
        return const [];
      }
      rethrow;
    }
  }
}

/// 无操作实现（测试用）。
class NoopPermissionRequester implements PermissionRequester {
  const NoopPermissionRequester();

  @override
  Future<List<String>> request(List<String> permissions) async => const [];
}
