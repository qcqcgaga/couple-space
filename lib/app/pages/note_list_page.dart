import 'package:flutter/material.dart';

import '../../core/models/note.dart';
import '../../services/note_service.dart';
import '../theme.dart';
import '../widgets/cute_empty.dart';
import '../widgets/note_card.dart';
import 'note_edit_page.dart';

/// 笔记列表（主视图）：默认首页，按时间倒序；筛选「全部 / 有日期」。
///
/// 不绑定时间的笔记同样正常显示，不视为未完成事项（docs/01 §5.1）。
class NoteListPage extends StatefulWidget {
  const NoteListPage({super.key, required this.service});

  final NoteService service;

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  bool _onlyBound = false;

  Future<void> _openEditor({Note? note}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NoteEditPage(service: widget.service, note: note),
      ),
    );
  }

  Future<void> _confirmDelete(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: const Text('删除后会同步到对方的设备，且不会被旧数据复活。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: CoupleColors.primaryDark,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.service.deleteNote(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('共享空间')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: '全部',
                  selected: !_onlyBound,
                  onTap: () => setState(() => _onlyBound = false),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '有日期',
                  selected: _onlyBound,
                  onTap: () => setState(() => _onlyBound = true),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Note>>(
              stream: widget.service.watchNotes(),
              builder: (context, snapshot) {
                final all = snapshot.data ?? const <Note>[];
                final notes = _onlyBound
                    ? [
                        for (final note in all)
                          if (note.timeBind != TimeBind.none) note,
                      ]
                    : all;
                if (notes.isEmpty) {
                  return _onlyBound
                      ? const CuteEmpty(
                          title: '还没有绑定时间的记录',
                          subtitle: '给重要的日子绑个时间，日历里就会有它啦~',
                        )
                      : const CuteEmpty(
                          title: '还没有记录',
                          subtitle: '一起写下第一笔吧~',
                        );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return NoteCard(
                      service: widget.service,
                      note: note,
                      onTap: () => _openEditor(note: note),
                      onEdit: () => _openEditor(note: note),
                      onDelete: () => _confirmDelete(note),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: '新建笔记',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? CoupleColors.primaryDark : CoupleColors.textLight,
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
