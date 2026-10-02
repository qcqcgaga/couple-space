import 'package:flutter/material.dart';

/// 简约可爱配色（docs/01 §9：圆角、柔和色、轻量插画元素）。
abstract final class CoupleColors {
  /// 背景：奶油白。
  static const Color background = Color(0xFFFFF8F5);

  /// 卡片/输入框表面。
  static const Color surface = Color(0xFFFFFFFF);

  /// 主色：软粉。
  static const Color primary = Color(0xFFF08CA4);

  /// 主色深一档（按压态/强调）。
  static const Color primaryDark = Color(0xFFDE6F89);

  /// 辅助色：天蓝。
  static const Color secondary = Color(0xFF9CC5E8);

  /// 正文深色。
  static const Color textDark = Color(0xFF4A3B42);

  /// 次要文字。
  static const Color textLight = Color(0xFF9A8C92);

  /// 柔和描边。
  static const Color border = Color(0xFFF3E0E5);

  /// 空态插画等轻量装饰色。
  static const Color blush = Color(0xFFFBE3EA);
}

/// 笔记分类颜色选项（柔和色板，hex 字符串入库）。
class NoteColorOption {
  const NoteColorOption(this.name, this.hex);

  final String name;
  final String hex;

  Color get color => Color(int.parse('FF$hex', radix: 16));
}

/// 分类/颜色色板（docs/01 §4：分类颜色为可选字段，简约配色）。
abstract final class NotePalette {
  static const List<NoteColorOption> options = [
    NoteColorOption('粉色', 'F08CA4'),
    NoteColorOption('薄荷', 'A9DCC9'),
    NoteColorOption('奶油黄', 'F7DFA9'),
    NoteColorOption('淡紫', 'CBB4E3'),
    NoteColorOption('天蓝', 'A5CFEC'),
    NoteColorOption('浅橙', 'F6BFA0'),
  ];

  /// 按 hex 找颜色；未知/空串返回柔和默认（粉色）。
  static Color colorOf(String? hex) {
    if (hex == null || hex.isEmpty) return CoupleColors.primary;
    for (final option in options) {
      if (option.hex == hex) return option.color;
    }
    return CoupleColors.primary;
  }

  /// 颜色名称（用于无障碍/选中态展示）。
  static String nameOf(String? hex) {
    if (hex == null || hex.isEmpty) return '无';
    for (final option in options) {
      if (option.hex == hex) return option.name;
    }
    return '无';
  }
}

/// 全局主题：Material 3 + 柔和粉色调 + 大圆角。
ThemeData buildCoupleTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CoupleColors.primary,
    brightness: Brightness.light,
    surface: CoupleColors.surface,
    primary: CoupleColors.primary,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CoupleColors.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: CoupleColors.textDark, height: 1.5),
      bodyLarge: TextStyle(color: CoupleColors.textDark, height: 1.5),
      titleMedium: TextStyle(color: CoupleColors.textDark),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: CoupleColors.background,
      foregroundColor: CoupleColors.textDark,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: CoupleColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: CoupleColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: CoupleColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoupleColors.surface,
      hintStyle: const TextStyle(color: CoupleColors.textLight),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CoupleColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CoupleColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CoupleColors.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoupleColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoupleColors.primaryDark,
        side: const BorderSide(color: CoupleColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CoupleColors.surface,
      indicatorColor: CoupleColors.blush,
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color: states.contains(WidgetState.selected)
              ? CoupleColors.primaryDark
              : CoupleColors.textLight,
          fontSize: 12,
          fontWeight:
              states.contains(WidgetState.selected) ? FontWeight.w600 : null,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? CoupleColors.primaryDark
              : CoupleColors.textLight,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CoupleColors.surface,
      selectedColor: CoupleColors.blush,
      side: const BorderSide(color: CoupleColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      labelStyle: const TextStyle(color: CoupleColors.textDark, fontSize: 13),
    ),
    dividerTheme: const DividerThemeData(
      color: CoupleColors.border,
      thickness: 1,
      space: 1,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: CoupleColors.primary,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: CoupleColors.textDark,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: CoupleColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: const TextStyle(
        color: CoupleColors.textDark,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CoupleColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
