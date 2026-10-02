import 'package:couple_space/app/home_shell.dart';
import 'package:couple_space/app/pages/note_list_page.dart';
import 'package:couple_space/app/widgets/month_calendar.dart';
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

  testWidgets('底部导航在笔记（主）与日历（辅助）之间切换', (tester) async {
    await tester.pumpWidget(appFor(HomeShell(notes: env.service)));
    await tester.pumpAndSettle();

    expect(find.byType(NoteListPage), findsOneWidget);
    expect(find.text('共享空间'), findsOneWidget);
    expect(find.byType(MonthCalendar), findsNothing);

    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();
    expect(find.byType(MonthCalendar), findsWidgets);

    await tester.tap(find.text('笔记'));
    await tester.pumpAndSettle();
    expect(find.byType(NoteListPage), findsOneWidget);
    await disposeTree(tester, env: env);
  });
}
