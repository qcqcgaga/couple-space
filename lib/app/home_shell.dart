import 'package:flutter/material.dart';

import '../services/note_service.dart';
import 'pages/calendar_page.dart';
import 'pages/note_list_page.dart';

/// 主页骨架：底部导航在「笔记（主视图）」与「日历（辅助视图）」之间切换。
///
/// 产品形态（ADR-012）：默认停在笔记列表；日历只展示绑定了时间的记录。
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.notes});

  final NoteService notes;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          NoteListPage(service: widget.notes),
          CalendarPage(service: widget.notes),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: '笔记',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '日历',
          ),
        ],
      ),
    );
  }
}
