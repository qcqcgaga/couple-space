import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 双进程同步引擎探针（docs/03-test-env.md §4 的 M1 扩展）：
/// 两个真实 Dart 进程通过 mDNS 发现 + TCP 建立连接，跑完整引擎——
/// 握手/配对、会话密钥协商、VersionMap 比对、NoteDelta/ImageMeta/ImageChunk、
/// 加密通道与图片分块传输，验证双端收敛。
void main() {
  test(
    '双进程 mDNS + TCP + 同步引擎（笔记 + 图片分块）',
    () async {
      final root = Directory.current.path;
      expect(File('$root/tool/probe.dart').existsSync(), isTrue,
          reason: '应从工程根目录运行 flutter test');

      final server = await Process.start(
        _dartExecutable(),
        [
          'run',
          'tool/probe.dart',
          'sync-server',
          '--id',
          'probe-sync-server',
          '--name',
          '同步服务器',
          '--mdns-port',
          '55353',
        ],
        workingDirectory: root,
      );
      final serverOut = StringBuffer();
      server.stdout.transform(utf8.decoder).listen(serverOut.write);
      final serverErr = StringBuffer();
      server.stderr.transform(utf8.decoder).listen(serverErr.write);

      final ready = await _waitForLine(
        serverOut,
        'READY id=probe-sync-server',
        timeout: const Duration(seconds: 90),
      );
      expect(ready, isTrue, reason: '服务器应输出 READY');

      final client = await Process.start(
        _dartExecutable(),
        [
          'run',
          'tool/probe.dart',
          'sync-client',
          '--find',
          'probe-sync-server',
          '--id',
          'probe-sync-client',
          '--name',
          '同步客户端',
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
          .timeout(const Duration(seconds: 150));
      expect(clientExit, 0,
          reason: '客户端失败输出:\n$clientErr\n$clientOut');
      expect(clientOut.toString(), contains('CLIENT-FOUND probe-sync-server'));
      expect(clientOut.toString(), contains('CLIENT-SYNC-OK'));
      expect(clientOut.toString(), contains('note=probe-note'));
      expect(clientOut.toString(), contains('image=probe-image'));

      final serverExit = await server.exitCode
          .timeout(const Duration(seconds: 90));
      expect(serverExit, 0,
          reason: '服务器输出:\n$serverOut\nstderr:\n$serverErr');
      expect(serverOut.toString(), contains('SERVER-SYNC-OK'));
      expect(serverOut.toString(), contains('note=probe-note'));
      expect(serverOut.toString(), contains('image=probe-image'));
    },
    timeout: const Timeout(Duration(seconds: 240)),
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
