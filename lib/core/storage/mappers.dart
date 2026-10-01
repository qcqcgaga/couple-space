import '../models/image.dart';
import '../models/note.dart';
import 'database.dart';

/// 领域模型与 drift 行数据的双向转换。
///
/// 时间统一以 epoch 毫秒存储；`timeBind` 存字符串枚举。
class NoteMapper {
  const NoteMapper._();

  static int? toMillis(DateTime? value) => value?.millisecondsSinceEpoch;

  static DateTime? fromMillis(int? value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);

  static TimeBind timeBindFrom(String value) =>
      TimeBind.values.firstWhere((e) => e.name == value, orElse: () => TimeBind.none);

  static Note toModel(NoteRow row, Map<String, FieldVersion> versions) {
    return Note(
      id: row.id,
      title: row.title,
      content: row.content,
      timeBind: timeBindFrom(row.timeBind),
      startAt: fromMillis(row.startAt),
      endAt: fromMillis(row.endAt),
      color: row.color,
      location: row.location,
      reminderOffsetMin: row.reminderOffsetMin,
      reminderAt: fromMillis(row.reminderAt),
      createdBy: row.createdBy,
      createdAt: fromMillis(row.createdAt),
      deleted: row.deleted,
      deletedAt: fromMillis(row.deletedAt),
      deletedBy: row.deletedBy,
      fieldVersions: versions,
    );
  }

  static NoteRow toRow(Note note) {
    return NoteRow(
      id: note.id,
      title: note.title,
      content: note.content,
      timeBind: note.timeBind.name,
      startAt: toMillis(note.startAt),
      endAt: toMillis(note.endAt),
      color: note.color,
      location: note.location,
      reminderOffsetMin: note.reminderOffsetMin,
      reminderAt: toMillis(note.reminderAt),
      createdBy: note.createdBy,
      createdAt: toMillis(note.createdAt),
      deleted: note.deleted,
      deletedAt: toMillis(note.deletedAt),
      deletedBy: note.deletedBy,
    );
  }

  static List<NoteFieldVersionRow> versionRows(Note note) {
    return [
      for (final entry in note.fieldVersions.entries)
        NoteFieldVersionRow(
          noteId: note.id,
          field: entry.key,
          lwTs: entry.value.ts,
          lwDevice: entry.value.deviceId,
        ),
    ];
  }
}

/// 图片元数据 <-> ImageRow。
class ImageMapper {
  const ImageMapper._();

  static ImageMeta toModel(ImageRow row) {
    return ImageMeta(
      id: row.id,
      noteId: row.noteId,
      fileName: row.fileName,
      sha256: row.sha256,
      size: row.size,
      deleted: row.deleted,
      deletedAt: NoteMapper.fromMillis(row.deletedAt),
      deletedBy: row.deletedBy,
      syncStatus: row.syncStatus,
      chunkBitmap: row.chunkBitmap,
      totalChunks: row.totalChunks,
      lwTs: row.lwTs,
      lwDevice: row.lwDevice,
    );
  }

  static ImageRow toRow(ImageMeta image) {
    return ImageRow(
      id: image.id,
      noteId: image.noteId,
      fileName: image.fileName,
      sha256: image.sha256,
      size: image.size,
      deleted: image.deleted,
      deletedAt: NoteMapper.toMillis(image.deletedAt),
      deletedBy: image.deletedBy,
      syncStatus: image.syncStatus,
      chunkBitmap: image.chunkBitmap,
      totalChunks: image.totalChunks,
      lwTs: image.lwTs,
      lwDevice: image.lwDevice,
    );
  }
}
