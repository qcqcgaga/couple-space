import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/note.dart';
import '../../services/note_service.dart';
import '../widgets/cute_empty.dart';
import '../widgets/note_card.dart';
import 'note_edit_page.dart';

/// 某一天的记录列表：复用笔记卡片，只显示覆盖该天的绑定时间记录。
class DayNotesPage extends StatelessWidget {
  const DayNotesPage({super.key, required this.service, required this.day});

  final NoteService service;
  final DateTime day;

  static final DateFormat _titleFormat = DateFormat('M月d日');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_titleFormat.format(day)} 的记录')),
      body: StreamBuilder<List<Note>>(
        stream: service.watchNotes(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? const <Note>[];
          final notes = [
            for (final note in all)
              if (NoteService.coversDay(note, day)) note,
          ];
          if (notes.isEmpty) {
            return const CuteEmpty(
              title: '这一天还没有记录',
              subtitle: '点右下角的加号，记下这一天的故事吧~',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                service: service,
                note: note,
                showTimeBadge: false,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          NoteEditPage(service: service, note: note),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '记一条',
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => NoteEditPage(
                service: service,
                initialDay: day,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
