/// 时间绑定方式：不绑定 / 全天（仅日期）/ 时间段（起止时间）。
///
/// 设计定位：重笔记、轻日历。不绑定时间的笔记只出现在笔记列表，
/// 绑定时间后同时出现在日历（提醒也仅对绑定时间的笔记有意义）。
enum TimeBind { none, allDay, range }

/// 字段级最后写入版本，用于 LWW 冲突解决。
///
/// 比较规则：时间戳大者胜；时间戳相同则设备 ID 字典序大者胜。
class FieldVersion {
  const FieldVersion(this.ts, this.deviceId);

  /// 毫秒时间戳（设备时钟）。
  final int ts;

  /// 写入方设备 ID。
  final String deviceId;

  int compareTo(FieldVersion other) {
    if (ts != other.ts) return ts.compareTo(other.ts);
    return deviceId.compareTo(other.deviceId);
  }

  bool winsOver(FieldVersion other) => compareTo(other) > 0;

  @override
  bool operator ==(Object other) =>
      other is FieldVersion && other.ts == ts && other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(ts, deviceId);

  @override
  String toString() => 'FieldVersion($ts, $deviceId)';
}

/// 共享笔记（记录）——本产品核心实体。
class Note {
  Note({
    required this.id,
    this.title,
    this.content = '',
    this.timeBind = TimeBind.none,
    this.startAt,
    this.endAt,
    this.color,
    this.location,
    this.reminderOffsetMin,
    this.reminderAt,
    this.createdBy,
    this.createdAt,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    Map<String, FieldVersion>? fieldVersions,
  }) : fieldVersions = fieldVersions ?? const {};

  final String id;

  /// 标题可选；缺省时应用层可用正文首行生成展示。
  final String? title;

  /// 正文主体。
  final String content;

  final TimeBind timeBind;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? color;
  final String? location;

  /// 提醒偏移（分钟）或具体提醒时间；仅绑定时间时有意义。
  final int? reminderOffsetMin;
  final DateTime? reminderAt;

  /// 写一次性字段（创建方与创建时间）。
  final String? createdBy;
  final DateTime? createdAt;

  /// 墓碑标记：删除视为对 deleted 字段的一次写入。
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// 可编辑字段的最后写入版本（字段名 -> 版本）。
  final Map<String, FieldVersion> fieldVersions;

  Note copyWith({
    String? title,
    String? content,
    TimeBind? timeBind,
    DateTime? startAt,
    DateTime? endAt,
    String? color,
    String? location,
    int? reminderOffsetMin,
    DateTime? reminderAt,
    bool? deleted,
    DateTime? deletedAt,
    String? deletedBy,
    Map<String, FieldVersion>? fieldVersions,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      timeBind: timeBind ?? this.timeBind,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      color: color ?? this.color,
      location: location ?? this.location,
      reminderOffsetMin: reminderOffsetMin ?? this.reminderOffsetMin,
      reminderAt: reminderAt ?? this.reminderAt,
      createdBy: createdBy,
      createdAt: createdAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      fieldVersions: fieldVersions ?? this.fieldVersions,
    );
  }
}
