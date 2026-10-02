import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/image.dart';
import '../../core/models/note.dart';
import '../../platform/image_picking.dart';
import '../../services/note_service.dart';
import '../theme.dart';

/// 新建/编辑笔记：正文输入为主（默认聚焦正文），时间、分类、提醒、图片
/// 都是可选区块（docs/01 §5.3）。
class NoteEditPage extends StatefulWidget {
  const NoteEditPage({
    super.key,
    required this.service,
    this.note,
    this.initialDay,
    this.imagePicker,
  });

  final NoteService service;

  /// 为 null 表示新建。
  final Note? note;

  /// 从日历某天进入新建时预设「全天 + 该日期」。
  final DateTime? initialDay;

  /// 图片选择抽象（测试注入假实现，默认系统相册/拍照）。
  final ImagePickerBridge? imagePicker;

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  static const List<({int minutes, String label})> _reminderPresets = [
    (minutes: 5, label: '提前 5 分钟'),
    (minutes: 10, label: '提前 10 分钟'),
    (minutes: 15, label: '提前 15 分钟'),
    (minutes: 30, label: '提前 30 分钟'),
    (minutes: 60, label: '提前 1 小时'),
  ];

  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _locationCtrl;
  late final ImagePickerBridge _picker;

  late TimeBind _timeBind;
  DateTime? _startAt;
  DateTime? _endAt;
  String? _color;
  int? _reminderOffsetMin;

  List<ImageMeta> _existing = [];
  final Set<String> _removedIds = {};
  final List<PickedImage> _picked = [];
  bool _loadingImages = false;
  bool _saving = false;

  /// 进入页面时的表单快照（用于判断是否有未保存修改）。
  late NoteDraft _initialDraft;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleCtrl = TextEditingController(text: note?.title ?? '');
    _contentCtrl = TextEditingController(text: note?.content ?? '');
    _locationCtrl = TextEditingController(text: note?.location ?? '');
    // 控制器变化时重建 PopScope，让 canPop 跟随「是否有未保存修改」。
    _titleCtrl.addListener(_onFormChanged);
    _contentCtrl.addListener(_onFormChanged);
    _locationCtrl.addListener(_onFormChanged);
    _picker = widget.imagePicker ?? SystemImagePicker();
    _timeBind = note?.timeBind ??
        (widget.initialDay != null ? TimeBind.allDay : TimeBind.none);
    _startAt = note?.startAt ?? widget.initialDay;
    _endAt = note?.endAt;
    _color = note?.color;
    _reminderOffsetMin = note?.reminderOffsetMin;

    _initialDraft = NoteDraft(
      title: note?.title,
      content: note?.content ?? '',
      timeBind: _timeBind,
      startAt: _startAt,
      endAt: _endAt,
      color: _color,
      location: note?.location,
      reminderOffsetMin: _reminderOffsetMin,
    );

    if (note != null) {
      _loadImages();
    }
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onFormChanged);
    _contentCtrl.removeListener(_onFormChanged);
    _locationCtrl.removeListener(_onFormChanged);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadImages() async {
    setState(() => _loadingImages = true);
    final images = await widget.service.imagesForNote(widget.note!.id);
    if (mounted) {
      setState(() {
        _existing = images;
        _loadingImages = false;
      });
    }
  }

  bool get _hasChanges {
    final initial = _initialDraft;
    return _titleCtrl.text.trim() != (initial.title?.trim() ?? '') ||
        _contentCtrl.text != initial.content ||
        _timeBind != initial.timeBind ||
        _startAt != initial.startAt ||
        _endAt != initial.endAt ||
        _color != initial.color ||
        _locationCtrl.text.trim() != (initial.location?.trim() ?? '') ||
        _reminderOffsetMin != initial.reminderOffsetMin ||
        _removedIds.isNotEmpty ||
        _picked.isNotEmpty;
  }

  NoteDraft get _draft => NoteDraft(
        title: _titleCtrl.text.trim().isEmpty
            ? null
            : _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        timeBind: _timeBind,
        startAt: _startAt,
        endAt: _endAt,
        color: _color,
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        reminderOffsetMin: _reminderOffsetMin,
      );

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      _showSnack('写点正文再保存吧~');
      return;
    }
    if (_timeBind == TimeBind.range && _startAt == null) {
      _showSnack('请选择时间段开始时间');
      return;
    }
    if (_timeBind == TimeBind.allDay && _startAt == null) {
      _showSnack('请选择日期');
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.note == null) {
        final created =
            await widget.service.createNote(_draft, images: _picked);
        if (mounted) Navigator.of(context).pop(created.id);
      } else {
        final id = widget.note!.id;
        await widget.service.updateNote(id, _draft);
        for (final removedId in _removedIds) {
          final image = _existing.firstWhere((e) => e.id == removedId);
          await widget.service.removeImage(image);
        }
        for (final picked in _picked) {
          await widget.service.addImage(
            id,
            sourcePath: picked.sourcePath,
            fileName: picked.fileName,
          );
        }
        if (mounted) Navigator.of(context).pop(id);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _showSnack('保存失败，请重试：$error');
      }
    }
  }

  Future<void> _delete() async {
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
      await widget.service.deleteNote(widget.note!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(
      initial: _startAt ?? DateTime.now(),
      title: '选择开始时间',
    );
    if (picked == null) return;
    setState(() {
      _startAt = picked;
      if (_timeBind == TimeBind.allDay) {
        _endAt = null;
      } else if (_endAt != null && _endAt!.isBefore(picked)) {
        _endAt = picked;
      }
    });
  }

  Future<void> _pickEnd() async {
    final base = _startAt ?? DateTime.now();
    final picked = await _pickDateTime(initial: _endAt ?? base, title: '选择结束时间');
    if (picked == null) return;
    setState(() => _endAt = picked.isBefore(base) ? base : picked);
  }

  Future<DateTime?> _pickDateTime({
    required DateTime initial,
    required String title,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: title,
      cancelText: '取消',
      confirmText: '确定',
    );
    if (!mounted) return null;
    if (date == null || _timeBind == TimeBind.allDay) return date;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: title,
      cancelText: '取消',
      confirmText: '确定',
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _askCustomReminder() async {
    final controller = TextEditingController();
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义提前提醒'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '提前多少分钟（至少 1）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, int.tryParse(controller.text.trim())),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (minutes != null && minutes > 0) {
      setState(() => _reminderOffsetMin = minutes);
    }
  }

  Future<void> _addImages() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'gallery') {
      final picked = await _picker.pickFromGallery();
      if (mounted && picked.isNotEmpty) {
        setState(() => _picked.addAll(picked));
      }
    } else {
      final picked = await _picker.pickFromCamera();
      if (mounted && picked != null) {
        setState(() => _picked.add(picked));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.note == null;
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_hasChanges) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('放弃修改？'),
            content: const Text('还有未保存的内容，确定要离开吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('继续编辑'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('放弃'),
              ),
            ],
          ),
        );
        if (leave == true && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(isNew ? '新建记录' : '编辑记录')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '标题（可选）',
                prefixIcon: Icon(
                  Icons.title_outlined,
                  color: CoupleColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              autofocus: isNew,
              minLines: 5,
              maxLines: 14,
              decoration: const InputDecoration(
                hintText: '写点什么吧…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('时间'),
            const SizedBox(height: 10),
            SegmentedButton<TimeBind>(
              segments: const [
                ButtonSegment(
                  value: TimeBind.none,
                  label: Text('不绑定'),
                ),
                ButtonSegment(
                  value: TimeBind.allDay,
                  label: Text('全天'),
                ),
                ButtonSegment(
                  value: TimeBind.range,
                  label: Text('时间段'),
                ),
              ],
              selected: {_timeBind},
              onSelectionChanged: (selection) {
                setState(() {
                  _timeBind = selection.single;
                  if (_timeBind == TimeBind.none) {
                    _startAt = null;
                    _endAt = null;
                    _reminderOffsetMin = null;
                  } else if (_timeBind == TimeBind.allDay && _startAt != null) {
                    _endAt = null;
                    // 全天只保留日期。
                    final start = _startAt!;
                    _startAt = DateTime(start.year, start.month, start.day);
                  }
                });
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (_timeBind != TimeBind.none) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: '开始',
                      value: _startAt,
                      onTap: _pickStart,
                    ),
                  ),
                  if (_timeBind == TimeBind.range) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: _TimeField(
                        label: '结束',
                        value: _endAt,
                        onTap: _pickEnd,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle('分类颜色'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ColorDot(
                  name: '无',
                  color: null,
                  selected: _color == null,
                  onTap: () => setState(() => _color = null),
                ),
                for (final option in NotePalette.options)
                  _ColorDot(
                    name: option.name,
                    color: option.color,
                    selected: _color == option.hex,
                    onTap: () => setState(() => _color = option.hex),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _SectionTitle('地点'),
            const SizedBox(height: 10),
            TextField(
              controller: _locationCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '地点（可选）',
                prefixIcon: Icon(
                  Icons.place_outlined,
                  color: CoupleColors.textLight,
                ),
              ),
            ),
            if (_timeBind != TimeBind.none) ...[
              const SizedBox(height: 20),
              const _SectionTitle('提醒'),
              const SizedBox(height: 10),
              _ReminderField(
                value: _reminderOffsetMin,
                onChanged: (value) => setState(() => _reminderOffsetMin = value),
                onCustom: _askCustomReminder,
              ),
            ],
            const SizedBox(height: 20),
            const _SectionTitle('图片'),
            const SizedBox(height: 10),
            if (_loadingImages)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final image in _existing)
                    if (!_removedIds.contains(image.id))
                      _ImageTile(
                        thumbnail: _ExistingThumbnail(
                          service: widget.service,
                          image: image,
                        ),
                        onRemove: () =>
                            setState(() => _removedIds.add(image.id)),
                      ),
                  for (final picked in _picked)
                    _ImageTile(
                      thumbnail: _PickedThumbnail(picked: picked),
                      onRemove: () => setState(() => _picked.remove(picked)),
                    ),
                  _AddImageTile(onTap: _addImages),
                ],
              ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                if (!isNew) ...[
                  OutlinedButton(
                    onPressed: _saving ? null : _delete,
                    child: const Text('删除'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: CoupleColors.textLight,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? '未选择'
        : DateFormat('M月d日 HH:mm').format(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(
            Icons.edit_calendar_outlined,
            size: 18,
            color: CoupleColors.primaryDark,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == null
                ? CoupleColors.textLight
                : CoupleColors.textDark,
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? CoupleColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? CoupleColors.primary : CoupleColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null)
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            Text(
              name,
              style: TextStyle(
                color: selected ? CoupleColors.primaryDark : CoupleColors.textDark,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderField extends StatelessWidget {
  const _ReminderField({
    required this.value,
    required this.onChanged,
    required this.onCustom,
  });

  final int? value;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final custom = value != null &&
        !_NoteEditPageState._reminderPresets.any((p) => p.minutes == value);
    return DropdownButtonFormField<int?>(
      initialValue: value,
      decoration: const InputDecoration(
        prefixIcon: Icon(
          Icons.notifications_outlined,
          color: CoupleColors.textLight,
        ),
      ),
      items: [
        const DropdownMenuItem<int?>(value: null, child: Text('不提醒')),
        for (final preset in _NoteEditPageState._reminderPresets)
          DropdownMenuItem<int?>(
            value: preset.minutes,
            child: Text(preset.label),
          ),
        if (custom)
          DropdownMenuItem<int?>(
            value: value,
            child: Text('提前 $value 分钟'),
          ),
        const DropdownMenuItem<int?>(value: -1, child: Text('自定义…')),
      ],
      onChanged: (selected) {
        if (selected == -1) {
          onCustom();
        } else {
          onChanged(selected);
        }
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.thumbnail, required this.onRemove});

  final Widget thumbnail;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(width: 72, height: 72, child: thumbnail),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: CoupleColors.textDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExistingThumbnail extends StatelessWidget {
  const _ExistingThumbnail({required this.service, required this.image});

  final NoteService service;
  final ImageMeta image;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: service.thumbnailFor(image),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const _ImagePlaceholder();
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          cacheWidth: 200,
          frameBuilder: (context, child, frame, wasSync) {
            if (frame == null) return const _ImagePlaceholder();
            return child;
          },
          errorBuilder: (context, error, stack) => const _ImagePlaceholder(),
        );
      },
    );
  }
}

class _PickedThumbnail extends StatelessWidget {
  const _PickedThumbnail({required this.picked});

  final PickedImage picked;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(picked.sourcePath),
      fit: BoxFit.cover,
      cacheWidth: 200,
      frameBuilder: (context, child, frame, wasSync) {
        if (frame == null) return const _ImagePlaceholder();
        return child;
      },
      errorBuilder: (context, error, stack) => const _ImagePlaceholder(),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: CoupleColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CoupleColors.border),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: CoupleColors.primary,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CoupleColors.blush,
      child: const Icon(
        Icons.image_outlined,
        size: 24,
        color: CoupleColors.primary,
      ),
    );
  }
}
