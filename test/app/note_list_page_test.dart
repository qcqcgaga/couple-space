import 'package:couple_space/app/pages/note_list_page.dart';
import 'package:couple_space/app/widgets/cute_empty.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/services/note_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';
import '../helpers/widget_harness.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    env = await TestEnv.create();
  });

  tearDown(() async {
    await env.dispose();
  });

  testWidgets('空态显示可爱文案与插画', (tester) async {
    await tester.pumpWidget(appFor(NoteListPage(service: env.service)));
    await tester.pumpAndSettle();

    expect(find.text('还没有记录'), findsOneWidget);
    expect(find.text('一起写下第一笔吧~'), findsOneWidget);
    expect(find.byType(CuteEmpty), findsOneWidget);
    await disposeTree(tester, env: env);
  });

  testWidgets('渲染笔记卡片（标题/正文/时间角标）并支持筛选', (tester) async {
    await env.service.createNote(
      const NoteDraft(title: '旅行', content: '海边散步'),
    );
    await env.service.createNote(
      NoteDraft(
        content: '我们的纪念日',
        timeBind: TimeBind.allDay,
        startAt: DateTime(2026, 10, 15),
      ),
    );
    await env.service.createNote(const NoteDraft(content: '周末随笔'));

    await tester.pumpWidget(appFor(NoteListPage(service: env.service)));
    await tester.pumpAndSettle();

    expect(find.text('旅行'), findsOneWidget);
    expect(find.text('海边散步'), findsOneWidget);
    expect(find.text('周末随笔'), findsOneWidget);
    expect(find.text('10月15日 · 全天'), findsOneWidget);

    // 全部 -> 有日期 筛选。
    await tester.tap(find.text('有日期'));
    await tester.pumpAndSettle();
    expect(find.text('旅行'), findsNothing);
    expect(find.text('周末随笔'), findsNothing);
    expect(find.text('我们的纪念日'), findsOneWidget);
    await disposeTree(tester, env: env);
  });

  testWidgets('FAB 打开新建记录页', (tester) async {
    await tester.pumpWidget(appFor(NoteListPage(service: env.service)));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('新建记录'), findsOneWidget);
    expect(find.text('写点什么吧…'), findsOneWidget);
    await disposeTree(tester, env: env);
  });

  testWidgets('菜单删除需要二次确认，确认后列表移除', (tester) async {
    await env.service.createNote(const NoteDraft(content: '要删除的笔记'));
    await tester.pumpWidget(appFor(NoteListPage(service: env.service)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(find.text('删除这条记录？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(await env.service.listNotes(), isEmpty);
    expect(find.text('还没有记录'), findsOneWidget);
    await disposeTree(tester, env: env);
  });
}
