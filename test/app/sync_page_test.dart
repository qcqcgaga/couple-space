import 'package:couple_space/app/pages/sync_page.dart';
import 'package:couple_space/core/sync/transports/transport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../helpers/fake_transport.dart';
import '../helpers/test_env.dart';
import '../helpers/widget_harness.dart';

void main() {
  testWidgets('空状态：显示发现提示、二维码与最近同步占位', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = (await tester.runAsync(() => TestEnv.create()))!;
    addTearDown(env.dispose);
    final sync = env.createSyncService();
    await tester.runAsync(() => sync.start());
    addTearDown(() => sync.stop());

    await tester.pumpWidget(appFor(SyncPage(sync: sync)));
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.textContaining('还没发现设备'), findsOneWidget);
    expect(find.textContaining('还没有同步记录'), findsOneWidget);
    expect(find.text('局域网发现中（自动连接已配对设备）'), findsOneWidget);
    await disposeTree(tester, env: env);
  });

  testWidgets('发现的未配对设备：显示配对按钮，且关闭自动连接时不发起连接', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final env = (await tester.runAsync(() => TestEnv.create()))!;
    addTearDown(env.dispose);
    final transport = FakeTransport();
    final sync = env.createSyncService(transport: transport);
    await tester.runAsync(() async {
      await sync.start();
      await sync.setAutoConnect(false);
    });
    addTearDown(() => sync.stop());

    await tester.pumpWidget(appFor(SyncPage(sync: sync)));
    await tester.pumpAndSettle();

    transport.emitDiscovery(
      const PeerDiscovered(peerId: 'deviceB', name: '小红的手机'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('小红的手机'), findsOneWidget);
    expect(find.textContaining('未配对'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '配对'), findsOneWidget);
    expect(transport.connectedPeerIds, isEmpty);
    await disposeTree(tester, env: env);
  });
}
