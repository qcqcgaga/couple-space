import 'package:couple_space/services/note_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_env.dart';
import '../helpers/widget_harness.dart';

void main() {
  late TestEnv env;

  setUp(() async {
    // 组件测试用内存图片导入器，避免真实文件 IO 挂起。
    env = await TestEnv.create(memoryImporter: true);
  });

  tearDown(() async {
    await env.dispose();
  });

  testWidgets('新建保存：正文必填校验，保存后落库', (tester) async {
    await pumpEditor(tester, service: env.service);

    // 空正文保存 -> 提示，不关闭页面。
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    expect(find.text('写点正文再保存吧~'), findsOneWidget);
    expect(find.text('新建记录'), findsOneWidget);

    // 填写正文并保存。
    await tester.enterText(find.byType(TextField).at(1), '第一笔记录');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final notes = await env.service.listNotes();
    expect(notes, hasLength(1));
    expect(notes.single.content, '第一笔记录');
    expect(find.text('新建记录'), findsNothing);
    await disposeTree(tester, env: env);
  });

  testWidgets('编辑已有笔记并保存', (tester) async {
    final note = await env.service.createNote(
      const NoteDraft(title: '旧标题', content: '旧正文'),
    );
    await pumpEditor(tester, service: env.service, note: note);

    expect(find.text('编辑记录'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '新标题');
    await tester.enterText(find.byType(TextField).at(1), '新正文');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final updated = await env.service.noteById(note.id);
    expect(updated!.title, '新标题');
    expect(updated.content, '新正文');
    await disposeTree(tester, env: env);
  });

  testWidgets('绑定时间后出现提醒区块，改回不绑定后隐藏', (tester) async {
    await pumpEditor(tester, service: env.service);

    expect(find.text('提醒'), findsNothing);
    await tester.tap(find.text('全天'));
    await tester.pumpAndSettle();
    expect(find.text('提醒'), findsOneWidget);
    expect(find.text('不提醒'), findsOneWidget);

    await tester.tap(find.text('不绑定'));
    await tester.pumpAndSettle();
    expect(find.text('提醒'), findsNothing);
    await disposeTree(tester, env: env);
  });

  testWidgets('相册多选图片：展示后可移除，保存后落库', (tester) async {
    await pumpEditor(
      tester,
      service: env.service,
      picker: FakeImagePicker(
        // 组件测试不访问真实文件（内存导入器 + 缩略图占位）。
        const [PickedImage(sourcePath: 'fake/photo.png', fileName: 'photo.png')],
      ),
    );

    // 添加图片。
    await tester.tap(find.byIcon(Icons.add_photo_alternate_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选择'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);

    // 保存后图片复制并落库。
    await tester.enterText(find.byType(TextField).at(1), '带图记录');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final notes = await env.service.listNotes();
    final images = await env.service.imagesForNote(notes.single.id);
    expect(images, hasLength(1));
    expect(images.single.fileName, 'photo.png');
    expect(images.single.sha256, startsWith('memory-'));
    await disposeTree(tester, env: env);
  });

  testWidgets('编辑页删除需要确认，确认后删除', (tester) async {
    final note = await env.service.createNote(
      const NoteDraft(content: '将被删除'),
    );
    await pumpEditor(tester, service: env.service, note: note);

    await tester.tap(find.widgetWithText(OutlinedButton, '删除'));
    await tester.pumpAndSettle();
    expect(find.text('删除这条记录？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(await env.service.listNotes(), isEmpty);
    await disposeTree(tester, env: env);
  });

  testWidgets('有未保存修改时返回需确认', (tester) async {
    await pumpEditor(tester, service: env.service);

    await tester.enterText(find.byType(TextField).at(1), '写了点东西');
    // 确认输入进入正文控制器（字段索引 1 = 正文）。
    final contentField = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(contentField.controller!.text, '写了点东西');
    // 先渲染一帧，让 PopScope 的 canPop 跟随表单变化。
    await tester.pump();
    // 模拟系统返回键，触发 PopScope 的拦截确认。
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('放弃修改？'), findsOneWidget);

    // 点「继续编辑」留在页面。
    await tester.tap(find.widgetWithText(TextButton, '继续编辑'));
    await tester.pumpAndSettle();
    expect(find.text('新建记录'), findsOneWidget);
    await disposeTree(tester, env: env);
  });
}
