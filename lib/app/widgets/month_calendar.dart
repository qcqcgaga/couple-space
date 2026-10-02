import 'package:flutter/material.dart';

import '../theme.dart';

/// 月历网格（辅助视图）：只标记有绑定时间记录的日子，今天高亮。
///
/// 周一开头（一二三四五六日）；点击某天进入当日笔记列表。
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.daysWithNotes,
    required this.onDayTap,
    this.today,
  });

  /// 当月第一天（用于定位年份/月份）。
  final DateTime month;

  /// 有记录的日子（只比较 y/m/d）。
  final Set<DateTime> daysWithNotes;

  final ValueChanged<DateTime> onDayTap;
  final DateTime? today;

  static const List<String> _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final cellCount = ((leadingBlanks + daysInMonth + 6) ~/ 7) * 7;

    return Column(
      children: [
        Row(
          children: [
            for (final weekday in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: const TextStyle(
                      color: CoupleColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // 固定单元格高度，避免月历在常见屏幕高度下纵向溢出。
          mainAxisExtent: 52,
          children: [
            for (var i = 0; i < cellCount; i++)
              if (i < leadingBlanks)
                const SizedBox.shrink()
              else
                _DayCell(
                  day: DateTime(month.year, month.month, i - leadingBlanks + 1),
                  hasNotes: daysWithNotes.contains(
                    DateTime(
                      month.year,
                      month.month,
                      i - leadingBlanks + 1,
                    ),
                  ),
                  isToday: today != null &&
                      today!.year == month.year &&
                      today!.month == month.month &&
                      today!.day == i - leadingBlanks + 1,
                  onTap: onDayTap,
                ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hasNotes,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool hasNotes;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(day),
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isToday ? CoupleColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isToday ? Colors.white : CoupleColors.textDark,
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 3),
          // 柔和的小圆点标记：最多 3 个。
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasNotes)
                for (var dot = 0; dot < 3; dot++)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: const BoxDecoration(
                      color: CoupleColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}
