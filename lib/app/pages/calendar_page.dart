import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/note.dart';
import '../../services/note_service.dart';
import '../theme.dart';
import '../widgets/month_calendar.dart';
import 'day_notes_page.dart';

/// 日历视图（辅助视图）：月网格，只有绑定时间的记录出现；
/// 左右滑动切换月份、今天高亮、点击某天进入当日记录列表。
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, required this.service, this.initialMonth});

  final NoteService service;

  /// 初始月份（测试可指定固定月份；默认当前月）。
  final DateTime? initialMonth;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final PageController _controller;
  int _index = 0;

  static final DateFormat _monthFormat = DateFormat('yyyy年M月');

  @override
  void initState() {
    super.initState();
    _index = _monthIndex(widget.initialMonth ?? DateTime.now());
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static int _monthIndex(DateTime day) => day.year * 12 + day.month - 1;

  static DateTime _monthFromIndex(int index) =>
      DateTime(index ~/ 12, index % 12 + 1);

  static Set<DateTime> _daysWithNotes(List<Note> notes, DateTime month) {
    final days = <DateTime>{};
    final last = DateTime(month.year, month.month + 1, 0);
    for (var day = DateTime(month.year, month.month, 1);
        !day.isAfter(last);
        day = day.add(const Duration(days: 1))) {
      final key = DateTime(day.year, day.month, day.day);
      for (final note in notes) {
        if (NoteService.coversDay(note, key)) {
          days.add(key);
          break;
        }
      }
    }
    return days;
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: StreamBuilder<List<Note>>(
        stream: widget.service.watchNotes(),
        builder: (context, snapshot) {
          final notes = snapshot.data ?? const <Note>[];
          final month = _monthFromIndex(_index);
          final currentMonth = _monthIndex(DateTime.now());
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => _goTo(_index - 1),
                      icon: const Icon(
                        Icons.chevron_left,
                        color: CoupleColors.primaryDark,
                      ),
                      tooltip: '上个月',
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _monthFormat.format(month),
                          style: const TextStyle(
                            color: CoupleColors.textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _goTo(_index + 1),
                      icon: const Icon(
                        Icons.chevron_right,
                        color: CoupleColors.primaryDark,
                      ),
                      tooltip: '下个月',
                    ),
                  ],
                ),
              ),
              if (_index != currentMonth)
                TextButton.icon(
                  onPressed: () => _goTo(currentMonth),
                  icon: const Icon(Icons.today_outlined, size: 16),
                  label: const Text('回到本月'),
                  style: TextButton.styleFrom(
                    foregroundColor: CoupleColors.primaryDark,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final pageMonth = _monthFromIndex(index);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: MonthCalendar(
                        month: pageMonth,
                        daysWithNotes: _daysWithNotes(notes, pageMonth),
                        today: DateTime.now(),
                        onDayTap: (day) => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                DayNotesPage(service: widget.service, day: day),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
