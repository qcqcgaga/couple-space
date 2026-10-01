import 'note.dart';

/// 笔记编辑/版本辅助：为可编辑字段统一生成 LWW 版本。
///
/// 删除视为对 `deleted` 字段的一次写入；删除元数据（deletedAt / deletedBy）
/// 跟随 deleted 字段的赢家（见 LwwResolver 的合并规则）。
class NoteVersions {
  const NoteVersions._();

  static const List<String> editableFields = [
    'title',
    'content',
    'timeBind',
    'startAt',
    'endAt',
    'color',
    'location',
    'reminderOffsetMin',
    'reminderAt',
    'deleted',
  ];

  /// 返回带 `fieldVersions` 的新笔记：每个可编辑字段都标记为
  /// 由 [deviceId] 在 [ts]（毫秒）写入。
  static Note stamped(Note note, {required String deviceId, required int ts}) {
    final versions = <String, FieldVersion>{
      for (final field in editableFields) field: FieldVersion(ts, deviceId),
    };
    return note.copyWith(fieldVersions: versions);
  }

  /// 笔记的最后更新毫秒时间戳：取全部字段版本的最大值；
  /// 没有版本时退化为创建时间或 0。
  static int lastUpdatedAt(Note note) {
    var ts = 0;
    for (final v in note.fieldVersions.values) {
      if (v.ts > ts) ts = v.ts;
    }
    return ts;
  }

  /// 生成用于 VersionMap 摘要的版本记录。
  static ({int ts, String deviceId, bool deleted}) summaryOf(Note note) {
    final device = note.fieldVersions['deleted']?.deviceId ??
        note.deletedBy ??
        note.createdBy ??
        '';
    return (
      ts: lastUpdatedAt(note),
      deviceId: device,
      deleted: note.deleted,
    );
  }
}
