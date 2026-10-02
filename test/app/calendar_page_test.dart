import 'package:couple_space/app/pages/calendar_page.dart';
import 'package:couple_space/app/pages/day_notes_page.dart';
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

  testWidgets('月历只标记绑定时间的记录，点击某天进入当日列表', (tester) async {
    await env.service.createNote(
      NoteDraft(
        content: '十月十五日纪念',
        timeBind: TimeBind.allDay,
        startAt: DateTime(2026, 10, 15),
      ),
    );
    await env.service.createNote(
      NoteDraft(
        content: '跨日行程',
        timeBind: TimeBind.range,
        startAt: DateTime(2026, 10, 20, 8),
        endAt: DateTime(2026, 10, 22, 18),
      ),
    );
    await env.service.createNote(const NoteDraft(content: '无日期随笔'));

    await tester.pumpWidget(
      appFor(CalendarPage(service: env.service, initialMonth: DateTime(2026, 10))),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026年10月'), findsOneWidget);

    // 点击 15 日 -> 当日记录页。
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('10月15日 的记录'), findsOneWidget);
    expect(find.text('十月十五日纪念'), findsOneWidget);
    expect(find.text('无日期随笔'), findsNothing);

    // 返回日历，点 21 日 -> 跨日记录覆盖的中间天。
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('21'));
    await tester.pumpAndSettle();
    expect(find.text('10月21日 的记录'), findsOneWidget);
    expect(find.text('跨日行程'), findsOneWidget);
    expect(find.text('十月十五日纪念'), findsNothing);
    await disposeTree(tester, env: env);
  });

  testWidgets('左右箭头切换月份', (tester) async {
    await tester.pumpWidget(
      appFor(CalendarPage(service: env.service, initialMonth: DateTime(2026, 10))),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('上个月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年9月'), findsOneWidget);

    await tester.tap(find.byTooltip('下个月'));
    await tester.pumpAndSettle();
    expect(find.text('2026年10月'), findsOneWidget);
    await disposeTree(tester, env: env);
  });

  testWidgets('当日记录页只显示当天内容，FAB 预设全天日期', (tester) async {
    await env.service.createNote(
      NoteDraft(
        content: '当天记录',
        timeBind: TimeBind.allDay,
        startAt: DateTime(2026, 10, 8),
      ),
    );
    await env.service.createNote(
      NoteDraft(
        content: '其他日期',
        timeBind: TimeBind.allDay,
        startAt: DateTime(2026, 10, 9),
      ),
    );

    await tester.pumpWidget(
      appFor(DayNotesPage(service: env.service, day: DateTime(2026, 10, 8))),
    );
    await tester.pumpAndSettle();

    expect(find.text('10月8日 的记录'), findsOneWidget);
    expect(find.text('当天记录'), findsOneWidget);
    expect(find.text('其他日期'), findsNothing);

    // 点加号 -> 新建记录页（全天已选中）。
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('新建记录'), findsOneWidget);
    expect(find.text('开始'), findsOneWidget);
    await disposeTree(tester, env: env);
  });
}
