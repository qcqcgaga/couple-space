import 'package:couple_space/app/theme.dart';
import 'package:couple_space/app/pages/note_edit_page.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/platform/image_picking.dart';
import 'package:couple_space/services/note_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_env.dart';

/// 组件测试外壳：中文 Material 文案 + 应用主题。
Widget appFor(Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildCoupleTheme(),
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

/// 测试收尾：卸载页面并推进一帧，让 drift 流关闭的 0 时长计时器触发，
/// 避免 flutter_test 报 “Timer is still pending”。
Future<void> disposeTree(WidgetTester tester, {TestEnv? env}) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 20));
  if (env != null) {
    await env.closeDatabase();
  }
}

/// 假图片选择器：固定返回给定图片，拍照返回空。
class FakeImagePicker implements ImagePickerBridge {
  FakeImagePicker(this.images);

  final List<PickedImage> images;

  @override
  Future<PickedImage?> pickFromCamera() async => null;

  @override
  Future<List<PickedImage>> pickFromGallery() async => images;
}

/// 先渲染一个空主页，再在首帧后把编辑页 push 上去；
/// 这样「保存/删除后 pop」有可返回的页面，避免 pop 根路由。
Future<void> pumpEditor(
  WidgetTester tester, {
  required NoteService service,
  Note? note,
  DateTime? initialDay,
  ImagePickerBridge? picker,
}) async {
  // 放大测试视口，让编辑页所有区块（提醒/图片等）都可见可点。
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildCoupleTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _EditorLauncher(
        builder: (_) => NoteEditPage(
          service: service,
          note: note,
          initialDay: initialDay,
          imagePicker: picker,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _EditorLauncher extends StatefulWidget {
  const _EditorLauncher({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_EditorLauncher> createState() => _EditorLauncherState();
}

class _EditorLauncherState extends State<_EditorLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: widget.builder),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.shrink());
  }
}
