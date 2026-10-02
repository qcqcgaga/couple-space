import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../services/app_services.dart';
import 'home_shell.dart';
import 'theme.dart';

/// 应用根组件：中文文案、简约可爱主题、笔记列表为主入口。
class CoupleSpaceApp extends StatelessWidget {
  const CoupleSpaceApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '情侣共享空间',
      debugShowCheckedModeBanner: false,
      theme: buildCoupleTheme(),
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeShell(notes: services.notes),
    );
  }
}
