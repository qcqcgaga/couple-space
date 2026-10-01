import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 探针 A 的自动化版本（docs/03-test-env.md §4）：
/// 启动两个真实 Dart 进程，走 mDNS 发现 + TCP + 分帧协议，完成 Hello/PeerInfo。
void main() {
  test(
    '双进程 mDNS + TCP + 分帧协议探针',
    () async {
      final root = Directory.current.path;
      expect(File('$root/tool/probe.dart').existsSync(), isTrue,
          reason: '应从工程根目录运行 flutter test');

      final server = await Process.start(
        _dartExecutable(),
        [
          'run',
          'tool/probe.dart',
          'server',
          '--id',
          'probe-server',
          '--name',
          '探针服务器',
          '--mdns-port',
          '55353',
        ],
        workingDirectory: root,
      );
      final serverOut = StringBuffer();
      server.stdout.transform(utf8.decoder).listen(serverOut.write);

      final ready = await _waitForLine(
        serverOut,
        'READY id=probe-server',
        timeout: const Duration(seconds: 90),
      );
      expect(ready, isTrue, reason: '服务器应输出 READY');

      final client = await Process.start(
        _dartExecutable(),
        [
          'run',
          'tool/probe.dart',
          'client',
          '--find',
          'probe-server',
          '--id',
          'probe-client',
          '--name',
          '探针客户端',
          '--mdns-port',
          '55353',
        ],
        workingDirectory: root,
      );
      final clientOut = StringBuffer();
      client.stdout.transform(utf8.decoder).listen(clientOut.write);
      final clientErr = StringBuffer();
      client.stderr.transform(utf8.decoder).listen(clientErr.write);

      final clientExit = await client.exitCode
          .timeout(const Duration(seconds: 120));
      expect(clientExit, 0,
          reason: '客户端失败输出:\n$clientErr\n$clientOut');
      expect(clientOut.toString(), contains('CLIENT-FOUND probe-server'));
      expect(clientOut.toString(), contains('CLIENT-SYNC-OK'));

      final serverExit = await server.exitCode
          .timeout(const Duration(seconds: 90));
      expect(serverExit, 0,
          reason: '服务器输出:\n$serverOut\nstderr 见上');
      expect(serverOut.toString(), contains('SERVER-OK'));
    },
    timeout: const Timeout(Duration(seconds: 180)),
  );
}

Future<bool> _waitForLine(
  StringBuffer buffer,
  String needle, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (buffer.toString().contains(needle)) return true;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  return buffer.toString().contains(needle);
}

/// flutter test 宿主里 [Platform.resolvedExecutable] 指向 flutter_tester，
/// 需要从 Flutter SDK 缓存目录定位真正的 dart 可执行文件。
String _dartExecutable() {
  final resolved = Platform.resolvedExecutable;
  final separator = Platform.pathSeparator;
  final segments = resolved.split(separator);
  final cacheIndex = segments.lastIndexOf('cache');
  if (cacheIndex >= 0) {
    final dartPath = [
      ...segments.take(cacheIndex + 1),
      'dart-sdk',
      'bin',
      'dart${Platform.isWindows ? '.exe' : ''}',
    ].join(separator);
    if (File(dartPath).existsSync()) return dartPath;
  }
  return resolved;
}
