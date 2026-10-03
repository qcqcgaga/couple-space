import 'package:couple_space/app/widgets/pairing_dialog.dart';
import 'package:couple_space/core/sync/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/widget_harness.dart';

void main() {
  const challenge = PairingChallenge(
    peerDeviceId: 'deviceB',
    code: '123456',
    verifiedByQr: true,
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    Future<void> Function(String code)? onConfirm,
    VoidCallback? onDismiss,
  }) {
    return tester.pumpWidget(
      appFor(
        Scaffold(
          body: PairingConfirmDialog(
            challenge: challenge,
            onConfirm: onConfirm ?? (code) async {},
            onDismiss: onDismiss,
          ),
        ),
      ),
    );
  }

  testWidgets('展示 6 位配对码与二维码提示；自动填入后可确认', (tester) async {
    String? confirmed;
    await pumpDialog(tester, onConfirm: (code) async => confirmed = code);
    await tester.pumpAndSettle();

    expect(find.text('配对确认'), findsOneWidget);
    expect(find.text('123456'), findsOneWidget);
    expect(find.text('已通过二维码锁定对方身份'), findsOneWidget);

    await tester.tap(find.text('两边一致，自动填入'));
    await tester.pump();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '123456');

    await tester.tap(find.text('确认配对'));
    await tester.pumpAndSettle();
    expect(confirmed, '123456');
    expect(find.byType(PairingConfirmDialog), findsNothing);
  });

  testWidgets('位数不足时不回调并提示', (tester) async {
    var called = false;
    await pumpDialog(tester, onConfirm: (code) async => called = true);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('确认配对'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.byType(PairingConfirmDialog), findsOneWidget);
    expect(find.text('请输入 6 位配对码'), findsOneWidget);
  });

  testWidgets('确认失败时提示且不关闭', (tester) async {
    await pumpDialog(
      tester,
      onConfirm: (code) async => throw Exception('sas_mismatch'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('确认配对'));
    await tester.pumpAndSettle();

    expect(find.byType(PairingConfirmDialog), findsOneWidget);
    expect(find.textContaining('配对失败'), findsOneWidget);
  });

  testWidgets('稍后再说触发回调并关闭', (tester) async {
    var dismissed = false;
    await pumpDialog(tester, onDismiss: () => dismissed = true);
    await tester.pumpAndSettle();

    await tester.tap(find.text('稍后再说'));
    await tester.pumpAndSettle();
    expect(dismissed, isTrue);
    expect(find.byType(PairingConfirmDialog), findsNothing);
  });
}
