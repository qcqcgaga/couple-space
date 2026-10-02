import 'dart:io';

import '../core/models/image.dart';
import '../core/models/note.dart';
import '../core/models/note_edit.dart';
import '../core/storage/daos.dart';
import '../core/storage/database.dart';
import '../core/storage/image_files.dart';
import '../core/storage/store.dart';
import '../core/storage/thumbnails.dart';
import '../core/utils/ids.dart';

/// 编辑表单草稿：UI 与用例层之间传递的纯数据。
///
/// 时间绑定三态（docs/02 §7）：不绑定 / 全天（仅日期）/ 时间段（起止）。
class NoteDraft {
  const NoteDraft({
    this.title,
    this.content = '',
    this.timeBind = TimeBind.none,
    this.startAt,
    this.endAt,
    this.color,
    this.location,
    this.reminderOffsetMin,
  });

  final String? title;
  final String content;
  final TimeBind timeBind;
  final DateTime? startAt;
  final DateTime? endAt;

  /// 分类颜色（柔和色板的 hex 字符串，见 app/theme.dart 的 NotePalette）。
  final String? color;

  /// 地点（纯文本，不做地图联动）。
  final String? location;

  /// 提醒偏移（分钟）；仅绑定时间时有意义，null 表示关闭。
  final int? reminderOffsetMin;
}

/// 本地待添加图片（从系统相册/拍照选出的原始文件）。
class PickedImage {
  const PickedImage({required this.sourcePath, this.fileName});

  final String sourcePath;

  /// 原始文件名（用于保留扩展名）。
  final String? fileName;
}

/// 图片导入端口：把本地源文件纳入应用图片存储（复制/哈希/缩略图）。
///
/// 生产用磁盘实现；组件测试注入内存实现，避免真实文件 IO 在
/// flutter_test 的假异步环境中挂起。
abstract interface class LocalImageImporter {
  /// 导入源文件并返回 (sha256, size)。
  Future<({String sha256, int size})> import(ImageMeta meta, String sourcePath);
}

/// 磁盘实现：复制原图到图片目录、生成缩略图、计算哈希与大小。
class DiskLocalImageImporter implements LocalImageImporter {
  DiskLocalImageImporter({required this.files, required this.thumbnails});

  final DiskImageFileStore files;
  final ThumbnailStore thumbnails;

  @override
  Future<({String sha256, int size})> import(
    ImageMeta meta,
    String sourcePath,
  ) async {
    final target = files.fileFor(meta);
    await target.parent.create(recursive: true);
    await File(sourcePath).copy(target.path);
    await thumbnails.ensureThumbnail(imageId: meta.id, sourceFile: target);
    return (sha256: await files.sha256(meta), size: await files.size(meta));
  }
}

/// 内存实现（测试用）：不访问磁盘，仍走完 LWW 落库链路。
class MemoryLocalImageImporter implements LocalImageImporter {
  const MemoryLocalImageImporter();

  @override
  Future<({String sha256, int size})> import(
    ImageMeta meta,
    String sourcePath,
  ) async {
    return (sha256: 'memory-${meta.id}', size: 0);
  }
}

/// 笔记用例层：CRUD、图片选择与管理、按日查询、缩略图。
///
/// 所有写入都带本机身份与毫秒时间戳，遵守字段级 LWW（时间戳大者胜，
/// 相同则设备 ID 大者胜）。M2 只负责本地落库；M3 接入同步引擎后，
/// 引擎复用同一套存储（DriftSyncStorage），UI 写入即可被同步。
class NoteService {
  NoteService({
    required this.db,
    required this.identityDeviceId,
    required this.files,
    required this.thumbnails,
    LocalImageImporter? importer,
  })  : _notes = NotesDao(db),
        _images = ImagesDao(db),
        _store = NoteStore(db),
        _importer =
            importer ?? DiskLocalImageImporter(files: files, thumbnails: thumbnails);

  final AppDatabase db;

  /// 本机设备 ID（local_identity 表），用于所有写入的 LWW 标记。
  final String identityDeviceId;

  /// 原图文件存储（生产：应用文档目录下 images/）。
  final DiskImageFileStore files;

  /// 缩略图缓存（列表/日历展示用）。
  final ThumbnailStore thumbnails;

  final NotesDao _notes;
  final ImagesDao _images;
  final NoteStore _store;
  final LocalImageImporter _importer;

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  Future<Note?> noteById(String id) => _notes.noteById(id);

  /// 全部可见笔记，按最后更新时间倒序（重笔记、轻日历的默认排列）。
  Future<List<Note>> listNotes({bool includeDeleted = false}) async {
    final notes = await _notes.allNotes(includeDeleted: includeDeleted);
    return _sortByLatest(notes);
  }

  /// 响应式监听可见笔记（notes / 字段版本 / 图片任一变化都会刷新）。
  Stream<List<Note>> watchNotes({bool includeDeleted = false}) {
    return _notes.watchNotes(includeDeleted: includeDeleted).map(_sortByLatest);
  }

  static List<Note> _sortByLatest(List<Note> notes) {
    final sorted = [...notes];
    sorted.sort((a, b) => _sortKey(b).compareTo(_sortKey(a)));
    return sorted;
  }

  /// 列表排序键：最后写入时间优先，退化为创建时间。
  static int _sortKey(Note note) {
    final updated = NoteVersions.lastUpdatedAt(note);
    if (updated > 0) return updated;
    return note.createdAt?.millisecondsSinceEpoch ?? 0;
  }

  /// 新建笔记：正文为主、标题可选、时间为可选属性；图片随后写入。
  Future<Note> createNote(
    NoteDraft draft, {
    List<PickedImage> images = const [],
  }) async {
    final now = _nowMs();
    final note = Note(
      id: Ids.uuid(),
      title: draft.title,
      content: draft.content,
      timeBind: draft.timeBind,
      startAt: draft.startAt,
      endAt: draft.endAt,
      color: draft.color,
      location: draft.location,
      reminderOffsetMin: draft.reminderOffsetMin,
      reminderAt: reminderAtFor(draft),
      createdAt: DateTime.fromMillisecondsSinceEpoch(now),
      createdBy: identityDeviceId,
    );
    final stamped =
        NoteVersions.stamped(note, deviceId: identityDeviceId, ts: now);
    await _notes.upsertNote(stamped);
    for (final image in images) {
      await addImage(
        stamped.id,
        sourcePath: image.sourcePath,
        fileName: image.fileName,
      );
    }
    return stamped;
  }

  /// 更新笔记：只对真正变化的字段重新打时间戳，保持字段级 LWW 语义
  /// （用户没改的字段不会覆盖对方更新的版本，ADR-025）。
  Future<Note> updateNote(String id, NoteDraft draft) async {
    final current = await _notes.noteById(id);
    if (current == null) {
      throw StateError('笔记不存在：$id');
    }
    final now = _nowMs();
    final versions = {...current.fieldVersions};

    void touch(String field, bool changed) {
      if (changed) {
        versions[field] = FieldVersion(now, identityDeviceId);
      }
    }

    final newReminderAt = reminderAtFor(draft);
    touch('title', current.title != draft.title);
    touch('content', current.content != draft.content);
    touch('timeBind', current.timeBind != draft.timeBind);
    touch('startAt', current.startAt != draft.startAt);
    touch('endAt', current.endAt != draft.endAt);
    touch('color', current.color != draft.color);
    touch('location', current.location != draft.location);
    touch(
      'reminderOffsetMin',
      current.reminderOffsetMin != draft.reminderOffsetMin,
    );
    touch('reminderAt', current.reminderAt != newReminderAt);

    // 直接构造新笔记而非 copyWith：copyWith 无法把 reminderAt 置空。
    final updated = Note(
      id: current.id,
      title: draft.title,
      content: draft.content,
      timeBind: draft.timeBind,
      startAt: draft.startAt,
      endAt: draft.endAt,
      color: draft.color,
      location: draft.location,
      reminderOffsetMin: draft.reminderOffsetMin,
      reminderAt: newReminderAt,
      createdBy: current.createdBy,
      createdAt: current.createdAt,
      deleted: current.deleted,
      deletedAt: current.deletedAt,
      deletedBy: current.deletedBy,
      fieldVersions: versions,
    );
    await _notes.upsertNote(updated);
    return updated;
  }

  /// 删除笔记：写入 deleted 字段（墓碑），对方同步后同样移除，且不会复活。
  Future<void> deleteNote(String id) {
    return _store.delete(id, deviceId: identityDeviceId, ts: _nowMs());
  }

  /// 某条笔记的可见图片（已删除的墓碑图片不返回；同步层仍可查全量）。
  Future<List<ImageMeta>> imagesForNote(String noteId) async {
    final all = await _images.imagesForNote(noteId);
    return [for (final image in all) if (!image.deleted) image];
  }

  /// 添加图片：复制原图到图片目录、计算 sha256/size、生成缩略图、落库。
  ///
  /// 图片以图片 ID 为粒度独立 LWW（添加/移除互不覆盖），单张大小不限制。
  Future<ImageMeta> addImage(
    String noteId, {
    required String sourcePath,
    String? fileName,
  }) async {
    final now = _nowMs();
    final id = Ids.uuid();
    final meta = ImageMeta(
      id: id,
      noteId: noteId,
      fileName: fileName ?? _baseNameOf(sourcePath),
      sha256: '',
      size: 0,
      syncStatus: 'pending',
      lwTs: now,
      lwDevice: identityDeviceId,
    );
    final imported = await _importer.import(meta, sourcePath);
    final saved = meta.copyWith(sha256: imported.sha256, size: imported.size);
    await _images.upsertImage(saved);
    return saved;
  }

  /// 移除图片：按图片 ID 写墓碑并删除本地原图与缩略图。
  Future<void> removeImage(ImageMeta image) async {
    await _images.markDeleted(
      image.id,
      deviceId: identityDeviceId,
      ts: _nowMs(),
    );
    await files.delete(image);
    await thumbnails.remove(image.id);
  }

  /// 取图片缩略图文件；未生成时按需生成，原图缺失/非图片时返回 null。
  Future<File?> thumbnailFor(ImageMeta image) {
    return thumbnails.ensureThumbnail(
      imageId: image.id,
      sourceFile: files.fileFor(image),
    );
  }

  /// 某一天可见的笔记（全天=当天；时间段=起止日期闭区间；不绑定=不出现）。
  Future<List<Note>> notesForDay(DateTime day) async {
    final all = await listNotes();
    return [for (final note in all) if (coversDay(note, day)) note];
  }

  /// 某月中有记录的日子集合（月历标记用，日期只保留 y/m/d）。
  Future<Set<DateTime>> daysWithNotesInMonth(int year, int month) async {
    final all = await listNotes();
    final result = <DateTime>{};
    final last = DateTime(year, month + 1, 0);
    for (var day = DateTime(year, month, 1);
        !day.isAfter(last);
        day = day.add(const Duration(days: 1))) {
      final key = DateTime(day.year, day.month, day.day);
      for (final note in all) {
        if (coversDay(note, key)) {
          result.add(key);
          break;
        }
      }
    }
    return result;
  }

  /// 笔记是否覆盖某一天（日期只比较 y/m/d，时区均为本地时间）。
  static bool coversDay(Note note, DateTime day) {
    if (note.timeBind == TimeBind.none) return false;
    final start = note.startAt;
    final end = note.endAt;

    // 全天：只覆盖 startAt 那一天。
    if (note.timeBind == TimeBind.allDay) {
      return start != null &&
          start.year == day.year &&
          start.month == day.month &&
          start.day == day.day;
    }

    // 时间段：起止日期闭区间；起点缺失按不绑定处理，终点缺省视为起点当天。
    if (start == null) return false;
    final effectiveEnd = end ?? start;
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd =
        dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    if (dayEnd.isBefore(start)) return false;
    if (dayStart.isAfter(effectiveEnd)) return false;
    return true;
  }

  /// 计算提醒触发时间（仅绑定时间时可设置提醒）。
  ///
  /// 规则（ADR-026）：不绑定无提醒；全天以当天 09:00 为基准（避免午夜提醒）；
  /// 时间段以 startAt 为基准；`reminderAt = 基准 - 提前分钟数`。
  static DateTime? reminderAtFor(NoteDraft draft) {
    final offset = draft.reminderOffsetMin;
    if (draft.timeBind == TimeBind.none || offset == null) return null;
    final start = draft.startAt;
    final DateTime? base;
    if (draft.timeBind == TimeBind.allDay) {
      base = start == null
          ? null
          : DateTime(start.year, start.month, start.day, 9);
    } else {
      base = start ?? draft.endAt;
    }
    if (base == null) return null;
    return base.subtract(Duration(minutes: offset));
  }

  static String _baseNameOf(String path) {
    final index = path.lastIndexOf(Platform.pathSeparator);
    final name = index < 0 ? path : path.substring(index + 1);
    return name.isEmpty ? 'image.jpg' : name;
  }
}
