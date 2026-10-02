import 'package:intl/intl.dart';

import '../../core/models/note.dart';

/// UI 文案格式化辅助（中文）。
abstract final class NoteFormat {
  const NoteFormat._();

  static final DateFormat _monthDay = DateFormat('M月d日');
  static final DateFormat _time = DateFormat('HH:mm');

  /// 卡片标题：优先标题；缺省由正文首行生成；都没有则「无标题」。
  static String displayTitle(Note note) {
    final title = note.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    final firstLine = note.content
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');
    return firstLine.isEmpty ? '无标题' : firstLine;
  }

  /// 时间角标文案：不绑定返回空；全天显示日期；时间段显示起止。
  static String timeBadge(Note note) {
    switch (note.timeBind) {
      case TimeBind.allDay:
        final start = note.startAt;
        if (start == null) return '';
        return '${_monthDay.format(start)} · 全天';
      case TimeBind.range:
        final start = note.startAt;
        final end = note.endAt;
        if (start == null && end == null) return '';
        if (start == null) return '${_monthDay.format(end!)} ${_time.format(end)}';
        if (end == null) return '${_monthDay.format(start)} ${_time.format(start)}';
        if (_sameDay(start, end)) {
          return '${_monthDay.format(start)} ${_time.format(start)} – ${_time.format(end)}';
        }
        return '${_monthDay.format(start)} ${_time.format(start)} – '
            '${_monthDay.format(end)} ${_time.format(end)}';
      case TimeBind.none:
        return '';
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
