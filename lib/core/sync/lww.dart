import '../models/note.dart';

/// 字段级 LWW（Last-Write-Wins）合并器。
///
/// 规则（见 docs/02-technical-design.md §8）：
/// 1. 比较 `(lwTs, lwDeviceId)`，大者胜；
/// 2. 每个字段独立比较；
/// 3. 删除视为对 `deleted` 字段的一次写入，删除元数据跟随 `deleted` 字段的赢家。
class LwwResolver {
  const LwwResolver();

  /// 合并本地与远端的两条笔记（同一 id），逐字段应用 LWW。
  Note merge(Note local, Note remote) {
    final lv = local.fieldVersions;
    final rv = remote.fieldVersions;

    // 版本表合并：每个字段保留较新版本。
    final mergedVersions = <String, FieldVersion>{...lv};
    rv.forEach((key, version) {
      final current = mergedVersions[key];
      if (current == null || version.compareTo(current) > 0) {
        mergedVersions[key] = version;
      }
    });

    T? pickNullable<T>(String key, T? localValue, T? remoteValue) {
      final a = lv[key];
      final b = rv[key];
      if (a == null && b == null) return localValue ?? remoteValue;
      if (a == null) return remoteValue;
      if (b == null) return localValue;
      return a.compareTo(b) >= 0 ? localValue : remoteValue;
    }

    T pick<T>(String key, T localValue, T remoteValue) =>
        pickNullable<T>(key, localValue, remoteValue) as T;

    return Note(
      id: local.id,
      title: pickNullable('title', local.title, remote.title),
      content: pick('content', local.content, remote.content),
      timeBind: pick('timeBind', local.timeBind, remote.timeBind),
      startAt: pickNullable('startAt', local.startAt, remote.startAt),
      endAt: pickNullable('endAt', local.endAt, remote.endAt),
      color: pickNullable('color', local.color, remote.color),
      location: pickNullable('location', local.location, remote.location),
      reminderOffsetMin: pickNullable(
        'reminderOffsetMin',
        local.reminderOffsetMin,
        remote.reminderOffsetMin,
      ),
      reminderAt: pickNullable('reminderAt', local.reminderAt, remote.reminderAt),
      deleted: pick('deleted', local.deleted, remote.deleted),
      deletedAt: pickNullable('deleted', local.deletedAt, remote.deletedAt),
      deletedBy: pickNullable('deleted', local.deletedBy, remote.deletedBy),
      createdBy: local.createdBy ?? remote.createdBy,
      createdAt: local.createdAt ?? remote.createdAt,
      fieldVersions: mergedVersions,
    );
  }
}
