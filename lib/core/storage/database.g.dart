// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NotesTable extends Notes with TableInfo<$NotesTable, NoteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _timeBindMeta = const VerificationMeta(
    'timeBind',
  );
  @override
  late final GeneratedColumn<String> timeBind = GeneratedColumn<String>(
    'time_bind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _startAtMeta = const VerificationMeta(
    'startAt',
  );
  @override
  late final GeneratedColumn<int> startAt = GeneratedColumn<int>(
    'start_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endAtMeta = const VerificationMeta('endAt');
  @override
  late final GeneratedColumn<int> endAt = GeneratedColumn<int>(
    'end_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderOffsetMinMeta = const VerificationMeta(
    'reminderOffsetMin',
  );
  @override
  late final GeneratedColumn<int> reminderOffsetMin = GeneratedColumn<int>(
    'reminder_offset_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderAtMeta = const VerificationMeta(
    'reminderAt',
  );
  @override
  late final GeneratedColumn<int> reminderAt = GeneratedColumn<int>(
    'reminder_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repeatRuleMeta = const VerificationMeta(
    'repeatRule',
  );
  @override
  late final GeneratedColumn<String> repeatRule = GeneratedColumn<String>(
    'repeat_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedByMeta = const VerificationMeta(
    'deletedBy',
  );
  @override
  late final GeneratedColumn<String> deletedBy = GeneratedColumn<String>(
    'deleted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    content,
    timeBind,
    startAt,
    endAt,
    color,
    location,
    reminderOffsetMin,
    reminderAt,
    repeatRule,
    createdBy,
    createdAt,
    deleted,
    deletedAt,
    deletedBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    }
    if (data.containsKey('time_bind')) {
      context.handle(
        _timeBindMeta,
        timeBind.isAcceptableOrUnknown(data['time_bind']!, _timeBindMeta),
      );
    }
    if (data.containsKey('start_at')) {
      context.handle(
        _startAtMeta,
        startAt.isAcceptableOrUnknown(data['start_at']!, _startAtMeta),
      );
    }
    if (data.containsKey('end_at')) {
      context.handle(
        _endAtMeta,
        endAt.isAcceptableOrUnknown(data['end_at']!, _endAtMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('reminder_offset_min')) {
      context.handle(
        _reminderOffsetMinMeta,
        reminderOffsetMin.isAcceptableOrUnknown(
          data['reminder_offset_min']!,
          _reminderOffsetMinMeta,
        ),
      );
    }
    if (data.containsKey('reminder_at')) {
      context.handle(
        _reminderAtMeta,
        reminderAt.isAcceptableOrUnknown(data['reminder_at']!, _reminderAtMeta),
      );
    }
    if (data.containsKey('repeat_rule')) {
      context.handle(
        _repeatRuleMeta,
        repeatRule.isAcceptableOrUnknown(data['repeat_rule']!, _repeatRuleMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('deleted_by')) {
      context.handle(
        _deletedByMeta,
        deletedBy.isAcceptableOrUnknown(data['deleted_by']!, _deletedByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NoteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      timeBind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_bind'],
      )!,
      startAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_at'],
      ),
      endAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_at'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      reminderOffsetMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_offset_min'],
      ),
      reminderAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_at'],
      ),
      repeatRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repeat_rule'],
      ),
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deletedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by'],
      ),
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }
}

class NoteRow extends DataClass implements Insertable<NoteRow> {
  final String id;

  /// 标题（可选）；缺省时应用层可用正文首行生成展示。
  final String? title;

  /// 正文主体。
  final String content;

  /// 时间绑定方式：none / allDay / range。
  final String timeBind;

  /// 绑定时间（epoch 毫秒）。allDay 时只记日期。
  final int? startAt;
  final int? endAt;
  final String? color;
  final String? location;
  final int? reminderOffsetMin;
  final int? reminderAt;

  /// 重复规则（v1 仅预留，不提供界面逻辑）。
  final String? repeatRule;
  final String? createdBy;
  final int? createdAt;
  final bool deleted;
  final int? deletedAt;
  final String? deletedBy;
  const NoteRow({
    required this.id,
    this.title,
    required this.content,
    required this.timeBind,
    this.startAt,
    this.endAt,
    this.color,
    this.location,
    this.reminderOffsetMin,
    this.reminderAt,
    this.repeatRule,
    this.createdBy,
    this.createdAt,
    required this.deleted,
    this.deletedAt,
    this.deletedBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['content'] = Variable<String>(content);
    map['time_bind'] = Variable<String>(timeBind);
    if (!nullToAbsent || startAt != null) {
      map['start_at'] = Variable<int>(startAt);
    }
    if (!nullToAbsent || endAt != null) {
      map['end_at'] = Variable<int>(endAt);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || reminderOffsetMin != null) {
      map['reminder_offset_min'] = Variable<int>(reminderOffsetMin);
    }
    if (!nullToAbsent || reminderAt != null) {
      map['reminder_at'] = Variable<int>(reminderAt);
    }
    if (!nullToAbsent || repeatRule != null) {
      map['repeat_rule'] = Variable<String>(repeatRule);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deletedBy != null) {
      map['deleted_by'] = Variable<String>(deletedBy);
    }
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      content: Value(content),
      timeBind: Value(timeBind),
      startAt: startAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startAt),
      endAt: endAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endAt),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      reminderOffsetMin: reminderOffsetMin == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderOffsetMin),
      reminderAt: reminderAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderAt),
      repeatRule: repeatRule == null && nullToAbsent
          ? const Value.absent()
          : Value(repeatRule),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      deleted: Value(deleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deletedBy: deletedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedBy),
    );
  }

  factory NoteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      content: serializer.fromJson<String>(json['content']),
      timeBind: serializer.fromJson<String>(json['timeBind']),
      startAt: serializer.fromJson<int?>(json['startAt']),
      endAt: serializer.fromJson<int?>(json['endAt']),
      color: serializer.fromJson<String?>(json['color']),
      location: serializer.fromJson<String?>(json['location']),
      reminderOffsetMin: serializer.fromJson<int?>(json['reminderOffsetMin']),
      reminderAt: serializer.fromJson<int?>(json['reminderAt']),
      repeatRule: serializer.fromJson<String?>(json['repeatRule']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<int?>(json['createdAt']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deletedBy: serializer.fromJson<String?>(json['deletedBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'content': serializer.toJson<String>(content),
      'timeBind': serializer.toJson<String>(timeBind),
      'startAt': serializer.toJson<int?>(startAt),
      'endAt': serializer.toJson<int?>(endAt),
      'color': serializer.toJson<String?>(color),
      'location': serializer.toJson<String?>(location),
      'reminderOffsetMin': serializer.toJson<int?>(reminderOffsetMin),
      'reminderAt': serializer.toJson<int?>(reminderAt),
      'repeatRule': serializer.toJson<String?>(repeatRule),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<int?>(createdAt),
      'deleted': serializer.toJson<bool>(deleted),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deletedBy': serializer.toJson<String?>(deletedBy),
    };
  }

  NoteRow copyWith({
    String? id,
    Value<String?> title = const Value.absent(),
    String? content,
    String? timeBind,
    Value<int?> startAt = const Value.absent(),
    Value<int?> endAt = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<String?> location = const Value.absent(),
    Value<int?> reminderOffsetMin = const Value.absent(),
    Value<int?> reminderAt = const Value.absent(),
    Value<String?> repeatRule = const Value.absent(),
    Value<String?> createdBy = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    bool? deleted,
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deletedBy = const Value.absent(),
  }) => NoteRow(
    id: id ?? this.id,
    title: title.present ? title.value : this.title,
    content: content ?? this.content,
    timeBind: timeBind ?? this.timeBind,
    startAt: startAt.present ? startAt.value : this.startAt,
    endAt: endAt.present ? endAt.value : this.endAt,
    color: color.present ? color.value : this.color,
    location: location.present ? location.value : this.location,
    reminderOffsetMin: reminderOffsetMin.present
        ? reminderOffsetMin.value
        : this.reminderOffsetMin,
    reminderAt: reminderAt.present ? reminderAt.value : this.reminderAt,
    repeatRule: repeatRule.present ? repeatRule.value : this.repeatRule,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    deleted: deleted ?? this.deleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deletedBy: deletedBy.present ? deletedBy.value : this.deletedBy,
  );
  NoteRow copyWithCompanion(NotesCompanion data) {
    return NoteRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      content: data.content.present ? data.content.value : this.content,
      timeBind: data.timeBind.present ? data.timeBind.value : this.timeBind,
      startAt: data.startAt.present ? data.startAt.value : this.startAt,
      endAt: data.endAt.present ? data.endAt.value : this.endAt,
      color: data.color.present ? data.color.value : this.color,
      location: data.location.present ? data.location.value : this.location,
      reminderOffsetMin: data.reminderOffsetMin.present
          ? data.reminderOffsetMin.value
          : this.reminderOffsetMin,
      reminderAt: data.reminderAt.present
          ? data.reminderAt.value
          : this.reminderAt,
      repeatRule: data.repeatRule.present
          ? data.repeatRule.value
          : this.repeatRule,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deletedBy: data.deletedBy.present ? data.deletedBy.value : this.deletedBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('timeBind: $timeBind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('color: $color, ')
          ..write('location: $location, ')
          ..write('reminderOffsetMin: $reminderOffsetMin, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    content,
    timeBind,
    startAt,
    endAt,
    color,
    location,
    reminderOffsetMin,
    reminderAt,
    repeatRule,
    createdBy,
    createdAt,
    deleted,
    deletedAt,
    deletedBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.content == this.content &&
          other.timeBind == this.timeBind &&
          other.startAt == this.startAt &&
          other.endAt == this.endAt &&
          other.color == this.color &&
          other.location == this.location &&
          other.reminderOffsetMin == this.reminderOffsetMin &&
          other.reminderAt == this.reminderAt &&
          other.repeatRule == this.repeatRule &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.deleted == this.deleted &&
          other.deletedAt == this.deletedAt &&
          other.deletedBy == this.deletedBy);
}

class NotesCompanion extends UpdateCompanion<NoteRow> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String> content;
  final Value<String> timeBind;
  final Value<int?> startAt;
  final Value<int?> endAt;
  final Value<String?> color;
  final Value<String?> location;
  final Value<int?> reminderOffsetMin;
  final Value<int?> reminderAt;
  final Value<String?> repeatRule;
  final Value<String?> createdBy;
  final Value<int?> createdAt;
  final Value<bool> deleted;
  final Value<int?> deletedAt;
  final Value<String?> deletedBy;
  final Value<int> rowid;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.timeBind = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.color = const Value.absent(),
    this.location = const Value.absent(),
    this.reminderOffsetMin = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    this.content = const Value.absent(),
    this.timeBind = const Value.absent(),
    this.startAt = const Value.absent(),
    this.endAt = const Value.absent(),
    this.color = const Value.absent(),
    this.location = const Value.absent(),
    this.reminderOffsetMin = const Value.absent(),
    this.reminderAt = const Value.absent(),
    this.repeatRule = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<NoteRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? content,
    Expression<String>? timeBind,
    Expression<int>? startAt,
    Expression<int>? endAt,
    Expression<String>? color,
    Expression<String>? location,
    Expression<int>? reminderOffsetMin,
    Expression<int>? reminderAt,
    Expression<String>? repeatRule,
    Expression<String>? createdBy,
    Expression<int>? createdAt,
    Expression<bool>? deleted,
    Expression<int>? deletedAt,
    Expression<String>? deletedBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (content != null) 'content': content,
      if (timeBind != null) 'time_bind': timeBind,
      if (startAt != null) 'start_at': startAt,
      if (endAt != null) 'end_at': endAt,
      if (color != null) 'color': color,
      if (location != null) 'location': location,
      if (reminderOffsetMin != null) 'reminder_offset_min': reminderOffsetMin,
      if (reminderAt != null) 'reminder_at': reminderAt,
      if (repeatRule != null) 'repeat_rule': repeatRule,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (deleted != null) 'deleted': deleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedBy != null) 'deleted_by': deletedBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? id,
    Value<String?>? title,
    Value<String>? content,
    Value<String>? timeBind,
    Value<int?>? startAt,
    Value<int?>? endAt,
    Value<String?>? color,
    Value<String?>? location,
    Value<int?>? reminderOffsetMin,
    Value<int?>? reminderAt,
    Value<String?>? repeatRule,
    Value<String?>? createdBy,
    Value<int?>? createdAt,
    Value<bool>? deleted,
    Value<int?>? deletedAt,
    Value<String?>? deletedBy,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      timeBind: timeBind ?? this.timeBind,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      color: color ?? this.color,
      location: location ?? this.location,
      reminderOffsetMin: reminderOffsetMin ?? this.reminderOffsetMin,
      reminderAt: reminderAt ?? this.reminderAt,
      repeatRule: repeatRule ?? this.repeatRule,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timeBind.present) {
      map['time_bind'] = Variable<String>(timeBind.value);
    }
    if (startAt.present) {
      map['start_at'] = Variable<int>(startAt.value);
    }
    if (endAt.present) {
      map['end_at'] = Variable<int>(endAt.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (reminderOffsetMin.present) {
      map['reminder_offset_min'] = Variable<int>(reminderOffsetMin.value);
    }
    if (reminderAt.present) {
      map['reminder_at'] = Variable<int>(reminderAt.value);
    }
    if (repeatRule.present) {
      map['repeat_rule'] = Variable<String>(repeatRule.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deletedBy.present) {
      map['deleted_by'] = Variable<String>(deletedBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('content: $content, ')
          ..write('timeBind: $timeBind, ')
          ..write('startAt: $startAt, ')
          ..write('endAt: $endAt, ')
          ..write('color: $color, ')
          ..write('location: $location, ')
          ..write('reminderOffsetMin: $reminderOffsetMin, ')
          ..write('reminderAt: $reminderAt, ')
          ..write('repeatRule: $repeatRule, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('deleted: $deleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NoteFieldVersionsTable extends NoteFieldVersions
    with TableInfo<$NoteFieldVersionsTable, NoteFieldVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NoteFieldVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id)',
    ),
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  @override
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lwTsMeta = const VerificationMeta('lwTs');
  @override
  late final GeneratedColumn<int> lwTs = GeneratedColumn<int>(
    'lw_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lwDeviceMeta = const VerificationMeta(
    'lwDevice',
  );
  @override
  late final GeneratedColumn<String> lwDevice = GeneratedColumn<String>(
    'lw_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, field, lwTs, lwDevice];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_field_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteFieldVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('lw_ts')) {
      context.handle(
        _lwTsMeta,
        lwTs.isAcceptableOrUnknown(data['lw_ts']!, _lwTsMeta),
      );
    } else if (isInserting) {
      context.missing(_lwTsMeta);
    }
    if (data.containsKey('lw_device')) {
      context.handle(
        _lwDeviceMeta,
        lwDevice.isAcceptableOrUnknown(data['lw_device']!, _lwDeviceMeta),
      );
    } else if (isInserting) {
      context.missing(_lwDeviceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, field};
  @override
  NoteFieldVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteFieldVersionRow(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      lwTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lw_ts'],
      )!,
      lwDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lw_device'],
      )!,
    );
  }

  @override
  $NoteFieldVersionsTable createAlias(String alias) {
    return $NoteFieldVersionsTable(attachedDatabase, alias);
  }
}

class NoteFieldVersionRow extends DataClass
    implements Insertable<NoteFieldVersionRow> {
  final String noteId;
  final String field;
  final int lwTs;
  final String lwDevice;
  const NoteFieldVersionRow({
    required this.noteId,
    required this.field,
    required this.lwTs,
    required this.lwDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['field'] = Variable<String>(field);
    map['lw_ts'] = Variable<int>(lwTs);
    map['lw_device'] = Variable<String>(lwDevice);
    return map;
  }

  NoteFieldVersionsCompanion toCompanion(bool nullToAbsent) {
    return NoteFieldVersionsCompanion(
      noteId: Value(noteId),
      field: Value(field),
      lwTs: Value(lwTs),
      lwDevice: Value(lwDevice),
    );
  }

  factory NoteFieldVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteFieldVersionRow(
      noteId: serializer.fromJson<String>(json['noteId']),
      field: serializer.fromJson<String>(json['field']),
      lwTs: serializer.fromJson<int>(json['lwTs']),
      lwDevice: serializer.fromJson<String>(json['lwDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'field': serializer.toJson<String>(field),
      'lwTs': serializer.toJson<int>(lwTs),
      'lwDevice': serializer.toJson<String>(lwDevice),
    };
  }

  NoteFieldVersionRow copyWith({
    String? noteId,
    String? field,
    int? lwTs,
    String? lwDevice,
  }) => NoteFieldVersionRow(
    noteId: noteId ?? this.noteId,
    field: field ?? this.field,
    lwTs: lwTs ?? this.lwTs,
    lwDevice: lwDevice ?? this.lwDevice,
  );
  NoteFieldVersionRow copyWithCompanion(NoteFieldVersionsCompanion data) {
    return NoteFieldVersionRow(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      field: data.field.present ? data.field.value : this.field,
      lwTs: data.lwTs.present ? data.lwTs.value : this.lwTs,
      lwDevice: data.lwDevice.present ? data.lwDevice.value : this.lwDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteFieldVersionRow(')
          ..write('noteId: $noteId, ')
          ..write('field: $field, ')
          ..write('lwTs: $lwTs, ')
          ..write('lwDevice: $lwDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, field, lwTs, lwDevice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteFieldVersionRow &&
          other.noteId == this.noteId &&
          other.field == this.field &&
          other.lwTs == this.lwTs &&
          other.lwDevice == this.lwDevice);
}

class NoteFieldVersionsCompanion extends UpdateCompanion<NoteFieldVersionRow> {
  final Value<String> noteId;
  final Value<String> field;
  final Value<int> lwTs;
  final Value<String> lwDevice;
  final Value<int> rowid;
  const NoteFieldVersionsCompanion({
    this.noteId = const Value.absent(),
    this.field = const Value.absent(),
    this.lwTs = const Value.absent(),
    this.lwDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NoteFieldVersionsCompanion.insert({
    required String noteId,
    required String field,
    required int lwTs,
    required String lwDevice,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       field = Value(field),
       lwTs = Value(lwTs),
       lwDevice = Value(lwDevice);
  static Insertable<NoteFieldVersionRow> custom({
    Expression<String>? noteId,
    Expression<String>? field,
    Expression<int>? lwTs,
    Expression<String>? lwDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (field != null) 'field': field,
      if (lwTs != null) 'lw_ts': lwTs,
      if (lwDevice != null) 'lw_device': lwDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NoteFieldVersionsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? field,
    Value<int>? lwTs,
    Value<String>? lwDevice,
    Value<int>? rowid,
  }) {
    return NoteFieldVersionsCompanion(
      noteId: noteId ?? this.noteId,
      field: field ?? this.field,
      lwTs: lwTs ?? this.lwTs,
      lwDevice: lwDevice ?? this.lwDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (lwTs.present) {
      map['lw_ts'] = Variable<int>(lwTs.value);
    }
    if (lwDevice.present) {
      map['lw_device'] = Variable<String>(lwDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteFieldVersionsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('field: $field, ')
          ..write('lwTs: $lwTs, ')
          ..write('lwDevice: $lwDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ImagesTable extends Images with TableInfo<$ImagesTable, ImageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notes (id)',
    ),
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedByMeta = const VerificationMeta(
    'deletedBy',
  );
  @override
  late final GeneratedColumn<String> deletedBy = GeneratedColumn<String>(
    'deleted_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _chunkBitmapMeta = const VerificationMeta(
    'chunkBitmap',
  );
  @override
  late final GeneratedColumn<String> chunkBitmap = GeneratedColumn<String>(
    'chunk_bitmap',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalChunksMeta = const VerificationMeta(
    'totalChunks',
  );
  @override
  late final GeneratedColumn<int> totalChunks = GeneratedColumn<int>(
    'total_chunks',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lwTsMeta = const VerificationMeta('lwTs');
  @override
  late final GeneratedColumn<int> lwTs = GeneratedColumn<int>(
    'lw_ts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lwDeviceMeta = const VerificationMeta(
    'lwDevice',
  );
  @override
  late final GeneratedColumn<String> lwDevice = GeneratedColumn<String>(
    'lw_device',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    noteId,
    fileName,
    sha256,
    size,
    deleted,
    deletedAt,
    deletedBy,
    syncStatus,
    chunkBitmap,
    totalChunks,
    lwTs,
    lwDevice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'images';
  @override
  VerificationContext validateIntegrity(
    Insertable<ImageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    } else if (isInserting) {
      context.missing(_sizeMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('deleted_by')) {
      context.handle(
        _deletedByMeta,
        deletedBy.isAcceptableOrUnknown(data['deleted_by']!, _deletedByMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('chunk_bitmap')) {
      context.handle(
        _chunkBitmapMeta,
        chunkBitmap.isAcceptableOrUnknown(
          data['chunk_bitmap']!,
          _chunkBitmapMeta,
        ),
      );
    }
    if (data.containsKey('total_chunks')) {
      context.handle(
        _totalChunksMeta,
        totalChunks.isAcceptableOrUnknown(
          data['total_chunks']!,
          _totalChunksMeta,
        ),
      );
    }
    if (data.containsKey('lw_ts')) {
      context.handle(
        _lwTsMeta,
        lwTs.isAcceptableOrUnknown(data['lw_ts']!, _lwTsMeta),
      );
    }
    if (data.containsKey('lw_device')) {
      context.handle(
        _lwDeviceMeta,
        lwDevice.isAcceptableOrUnknown(data['lw_device']!, _lwDeviceMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ImageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ImageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      deletedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      chunkBitmap: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chunk_bitmap'],
      ),
      totalChunks: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chunks'],
      )!,
      lwTs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lw_ts'],
      )!,
      lwDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lw_device'],
      )!,
    );
  }

  @override
  $ImagesTable createAlias(String alias) {
    return $ImagesTable(attachedDatabase, alias);
  }
}

class ImageRow extends DataClass implements Insertable<ImageRow> {
  final String id;
  final String noteId;
  final String fileName;
  final String sha256;
  final int size;
  final bool deleted;
  final int? deletedAt;
  final String? deletedBy;

  /// pending / partial / done。
  final String syncStatus;

  /// 已收块位图（逗号分隔的 0/1），用于断点续传。
  final String? chunkBitmap;

  /// 分块总数（续传需要）。
  final int totalChunks;

  /// 图片级 LWW 版本（添加/删除各自独立）。
  final int lwTs;
  final String lwDevice;
  const ImageRow({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.sha256,
    required this.size,
    required this.deleted,
    this.deletedAt,
    this.deletedBy,
    required this.syncStatus,
    this.chunkBitmap,
    required this.totalChunks,
    required this.lwTs,
    required this.lwDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['note_id'] = Variable<String>(noteId);
    map['file_name'] = Variable<String>(fileName);
    map['sha256'] = Variable<String>(sha256);
    map['size'] = Variable<int>(size);
    map['deleted'] = Variable<bool>(deleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deletedBy != null) {
      map['deleted_by'] = Variable<String>(deletedBy);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || chunkBitmap != null) {
      map['chunk_bitmap'] = Variable<String>(chunkBitmap);
    }
    map['total_chunks'] = Variable<int>(totalChunks);
    map['lw_ts'] = Variable<int>(lwTs);
    map['lw_device'] = Variable<String>(lwDevice);
    return map;
  }

  ImagesCompanion toCompanion(bool nullToAbsent) {
    return ImagesCompanion(
      id: Value(id),
      noteId: Value(noteId),
      fileName: Value(fileName),
      sha256: Value(sha256),
      size: Value(size),
      deleted: Value(deleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deletedBy: deletedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedBy),
      syncStatus: Value(syncStatus),
      chunkBitmap: chunkBitmap == null && nullToAbsent
          ? const Value.absent()
          : Value(chunkBitmap),
      totalChunks: Value(totalChunks),
      lwTs: Value(lwTs),
      lwDevice: Value(lwDevice),
    );
  }

  factory ImageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ImageRow(
      id: serializer.fromJson<String>(json['id']),
      noteId: serializer.fromJson<String>(json['noteId']),
      fileName: serializer.fromJson<String>(json['fileName']),
      sha256: serializer.fromJson<String>(json['sha256']),
      size: serializer.fromJson<int>(json['size']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deletedBy: serializer.fromJson<String?>(json['deletedBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      chunkBitmap: serializer.fromJson<String?>(json['chunkBitmap']),
      totalChunks: serializer.fromJson<int>(json['totalChunks']),
      lwTs: serializer.fromJson<int>(json['lwTs']),
      lwDevice: serializer.fromJson<String>(json['lwDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'noteId': serializer.toJson<String>(noteId),
      'fileName': serializer.toJson<String>(fileName),
      'sha256': serializer.toJson<String>(sha256),
      'size': serializer.toJson<int>(size),
      'deleted': serializer.toJson<bool>(deleted),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deletedBy': serializer.toJson<String?>(deletedBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'chunkBitmap': serializer.toJson<String?>(chunkBitmap),
      'totalChunks': serializer.toJson<int>(totalChunks),
      'lwTs': serializer.toJson<int>(lwTs),
      'lwDevice': serializer.toJson<String>(lwDevice),
    };
  }

  ImageRow copyWith({
    String? id,
    String? noteId,
    String? fileName,
    String? sha256,
    int? size,
    bool? deleted,
    Value<int?> deletedAt = const Value.absent(),
    Value<String?> deletedBy = const Value.absent(),
    String? syncStatus,
    Value<String?> chunkBitmap = const Value.absent(),
    int? totalChunks,
    int? lwTs,
    String? lwDevice,
  }) => ImageRow(
    id: id ?? this.id,
    noteId: noteId ?? this.noteId,
    fileName: fileName ?? this.fileName,
    sha256: sha256 ?? this.sha256,
    size: size ?? this.size,
    deleted: deleted ?? this.deleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    deletedBy: deletedBy.present ? deletedBy.value : this.deletedBy,
    syncStatus: syncStatus ?? this.syncStatus,
    chunkBitmap: chunkBitmap.present ? chunkBitmap.value : this.chunkBitmap,
    totalChunks: totalChunks ?? this.totalChunks,
    lwTs: lwTs ?? this.lwTs,
    lwDevice: lwDevice ?? this.lwDevice,
  );
  ImageRow copyWithCompanion(ImagesCompanion data) {
    return ImageRow(
      id: data.id.present ? data.id.value : this.id,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      size: data.size.present ? data.size.value : this.size,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deletedBy: data.deletedBy.present ? data.deletedBy.value : this.deletedBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      chunkBitmap: data.chunkBitmap.present
          ? data.chunkBitmap.value
          : this.chunkBitmap,
      totalChunks: data.totalChunks.present
          ? data.totalChunks.value
          : this.totalChunks,
      lwTs: data.lwTs.present ? data.lwTs.value : this.lwTs,
      lwDevice: data.lwDevice.present ? data.lwDevice.value : this.lwDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ImageRow(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('fileName: $fileName, ')
          ..write('sha256: $sha256, ')
          ..write('size: $size, ')
          ..write('deleted: $deleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('chunkBitmap: $chunkBitmap, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('lwTs: $lwTs, ')
          ..write('lwDevice: $lwDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    noteId,
    fileName,
    sha256,
    size,
    deleted,
    deletedAt,
    deletedBy,
    syncStatus,
    chunkBitmap,
    totalChunks,
    lwTs,
    lwDevice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ImageRow &&
          other.id == this.id &&
          other.noteId == this.noteId &&
          other.fileName == this.fileName &&
          other.sha256 == this.sha256 &&
          other.size == this.size &&
          other.deleted == this.deleted &&
          other.deletedAt == this.deletedAt &&
          other.deletedBy == this.deletedBy &&
          other.syncStatus == this.syncStatus &&
          other.chunkBitmap == this.chunkBitmap &&
          other.totalChunks == this.totalChunks &&
          other.lwTs == this.lwTs &&
          other.lwDevice == this.lwDevice);
}

class ImagesCompanion extends UpdateCompanion<ImageRow> {
  final Value<String> id;
  final Value<String> noteId;
  final Value<String> fileName;
  final Value<String> sha256;
  final Value<int> size;
  final Value<bool> deleted;
  final Value<int?> deletedAt;
  final Value<String?> deletedBy;
  final Value<String> syncStatus;
  final Value<String?> chunkBitmap;
  final Value<int> totalChunks;
  final Value<int> lwTs;
  final Value<String> lwDevice;
  final Value<int> rowid;
  const ImagesCompanion({
    this.id = const Value.absent(),
    this.noteId = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.size = const Value.absent(),
    this.deleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.chunkBitmap = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.lwTs = const Value.absent(),
    this.lwDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ImagesCompanion.insert({
    required String id,
    required String noteId,
    required String fileName,
    required String sha256,
    required int size,
    this.deleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.chunkBitmap = const Value.absent(),
    this.totalChunks = const Value.absent(),
    this.lwTs = const Value.absent(),
    this.lwDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       noteId = Value(noteId),
       fileName = Value(fileName),
       sha256 = Value(sha256),
       size = Value(size);
  static Insertable<ImageRow> custom({
    Expression<String>? id,
    Expression<String>? noteId,
    Expression<String>? fileName,
    Expression<String>? sha256,
    Expression<int>? size,
    Expression<bool>? deleted,
    Expression<int>? deletedAt,
    Expression<String>? deletedBy,
    Expression<String>? syncStatus,
    Expression<String>? chunkBitmap,
    Expression<int>? totalChunks,
    Expression<int>? lwTs,
    Expression<String>? lwDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (noteId != null) 'note_id': noteId,
      if (fileName != null) 'file_name': fileName,
      if (sha256 != null) 'sha256': sha256,
      if (size != null) 'size': size,
      if (deleted != null) 'deleted': deleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedBy != null) 'deleted_by': deletedBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (chunkBitmap != null) 'chunk_bitmap': chunkBitmap,
      if (totalChunks != null) 'total_chunks': totalChunks,
      if (lwTs != null) 'lw_ts': lwTs,
      if (lwDevice != null) 'lw_device': lwDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ImagesCompanion copyWith({
    Value<String>? id,
    Value<String>? noteId,
    Value<String>? fileName,
    Value<String>? sha256,
    Value<int>? size,
    Value<bool>? deleted,
    Value<int?>? deletedAt,
    Value<String?>? deletedBy,
    Value<String>? syncStatus,
    Value<String?>? chunkBitmap,
    Value<int>? totalChunks,
    Value<int>? lwTs,
    Value<String>? lwDevice,
    Value<int>? rowid,
  }) {
    return ImagesCompanion(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      fileName: fileName ?? this.fileName,
      sha256: sha256 ?? this.sha256,
      size: size ?? this.size,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      syncStatus: syncStatus ?? this.syncStatus,
      chunkBitmap: chunkBitmap ?? this.chunkBitmap,
      totalChunks: totalChunks ?? this.totalChunks,
      lwTs: lwTs ?? this.lwTs,
      lwDevice: lwDevice ?? this.lwDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deletedBy.present) {
      map['deleted_by'] = Variable<String>(deletedBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (chunkBitmap.present) {
      map['chunk_bitmap'] = Variable<String>(chunkBitmap.value);
    }
    if (totalChunks.present) {
      map['total_chunks'] = Variable<int>(totalChunks.value);
    }
    if (lwTs.present) {
      map['lw_ts'] = Variable<int>(lwTs.value);
    }
    if (lwDevice.present) {
      map['lw_device'] = Variable<String>(lwDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ImagesCompanion(')
          ..write('id: $id, ')
          ..write('noteId: $noteId, ')
          ..write('fileName: $fileName, ')
          ..write('sha256: $sha256, ')
          ..write('size: $size, ')
          ..write('deleted: $deleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('chunkBitmap: $chunkBitmap, ')
          ..write('totalChunks: $totalChunks, ')
          ..write('lwTs: $lwTs, ')
          ..write('lwDevice: $lwDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TombstonesTable extends Tombstones
    with TableInfo<$TombstonesTable, TombstoneRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedByMeta = const VerificationMeta(
    'deletedBy',
  );
  @override
  late final GeneratedColumn<String> deletedBy = GeneratedColumn<String>(
    'deleted_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<int> confirmedAt = GeneratedColumn<int>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    deletedAt,
    deletedBy,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<TombstoneRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedAtMeta);
    }
    if (data.containsKey('deleted_by')) {
      context.handle(
        _deletedByMeta,
        deletedBy.isAcceptableOrUnknown(data['deleted_by']!, _deletedByMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedByMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId};
  @override
  TombstoneRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TombstoneRow(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      )!,
      deletedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $TombstonesTable createAlias(String alias) {
    return $TombstonesTable(attachedDatabase, alias);
  }
}

class TombstoneRow extends DataClass implements Insertable<TombstoneRow> {
  final String recordId;
  final int deletedAt;
  final String deletedBy;
  final int? confirmedAt;
  const TombstoneRow({
    required this.recordId,
    required this.deletedAt,
    required this.deletedBy,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['deleted_at'] = Variable<int>(deletedAt);
    map['deleted_by'] = Variable<String>(deletedBy);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<int>(confirmedAt);
    }
    return map;
  }

  TombstonesCompanion toCompanion(bool nullToAbsent) {
    return TombstonesCompanion(
      recordId: Value(recordId),
      deletedAt: Value(deletedAt),
      deletedBy: Value(deletedBy),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory TombstoneRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TombstoneRow(
      recordId: serializer.fromJson<String>(json['recordId']),
      deletedAt: serializer.fromJson<int>(json['deletedAt']),
      deletedBy: serializer.fromJson<String>(json['deletedBy']),
      confirmedAt: serializer.fromJson<int?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'deletedAt': serializer.toJson<int>(deletedAt),
      'deletedBy': serializer.toJson<String>(deletedBy),
      'confirmedAt': serializer.toJson<int?>(confirmedAt),
    };
  }

  TombstoneRow copyWith({
    String? recordId,
    int? deletedAt,
    String? deletedBy,
    Value<int?> confirmedAt = const Value.absent(),
  }) => TombstoneRow(
    recordId: recordId ?? this.recordId,
    deletedAt: deletedAt ?? this.deletedAt,
    deletedBy: deletedBy ?? this.deletedBy,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  TombstoneRow copyWithCompanion(TombstonesCompanion data) {
    return TombstoneRow(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deletedBy: data.deletedBy.present ? data.deletedBy.value : this.deletedBy,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TombstoneRow(')
          ..write('recordId: $recordId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordId, deletedAt, deletedBy, confirmedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TombstoneRow &&
          other.recordId == this.recordId &&
          other.deletedAt == this.deletedAt &&
          other.deletedBy == this.deletedBy &&
          other.confirmedAt == this.confirmedAt);
}

class TombstonesCompanion extends UpdateCompanion<TombstoneRow> {
  final Value<String> recordId;
  final Value<int> deletedAt;
  final Value<String> deletedBy;
  final Value<int?> confirmedAt;
  final Value<int> rowid;
  const TombstonesCompanion({
    this.recordId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deletedBy = const Value.absent(),
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TombstonesCompanion.insert({
    required String recordId,
    required int deletedAt,
    required String deletedBy,
    this.confirmedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       deletedAt = Value(deletedAt),
       deletedBy = Value(deletedBy);
  static Insertable<TombstoneRow> custom({
    Expression<String>? recordId,
    Expression<int>? deletedAt,
    Expression<String>? deletedBy,
    Expression<int>? confirmedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deletedBy != null) 'deleted_by': deletedBy,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TombstonesCompanion copyWith({
    Value<String>? recordId,
    Value<int>? deletedAt,
    Value<String>? deletedBy,
    Value<int?>? confirmedAt,
    Value<int>? rowid,
  }) {
    return TombstonesCompanion(
      recordId: recordId ?? this.recordId,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deletedBy.present) {
      map['deleted_by'] = Variable<String>(deletedBy.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<int>(confirmedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TombstonesCompanion(')
          ..write('recordId: $recordId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deletedBy: $deletedBy, ')
          ..write('confirmedAt: $confirmedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PeersTable extends Peers with TableInfo<$PeersTable, PeerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PeersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identityPublicKeyMeta = const VerificationMeta(
    'identityPublicKey',
  );
  @override
  late final GeneratedColumn<String> identityPublicKey =
      GeneratedColumn<String>(
        'identity_public_key',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _pairedAtMeta = const VerificationMeta(
    'pairedAt',
  );
  @override
  late final GeneratedColumn<int> pairedAt = GeneratedColumn<int>(
    'paired_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastConnectedAtMeta = const VerificationMeta(
    'lastConnectedAt',
  );
  @override
  late final GeneratedColumn<int> lastConnectedAt = GeneratedColumn<int>(
    'last_connected_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    name,
    identityPublicKey,
    pairedAt,
    lastConnectedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'peers';
  @override
  VerificationContext validateIntegrity(
    Insertable<PeerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('identity_public_key')) {
      context.handle(
        _identityPublicKeyMeta,
        identityPublicKey.isAcceptableOrUnknown(
          data['identity_public_key']!,
          _identityPublicKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_identityPublicKeyMeta);
    }
    if (data.containsKey('paired_at')) {
      context.handle(
        _pairedAtMeta,
        pairedAt.isAcceptableOrUnknown(data['paired_at']!, _pairedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_pairedAtMeta);
    }
    if (data.containsKey('last_connected_at')) {
      context.handle(
        _lastConnectedAtMeta,
        lastConnectedAt.isAcceptableOrUnknown(
          data['last_connected_at']!,
          _lastConnectedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  PeerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PeerRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      identityPublicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_public_key'],
      )!,
      pairedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paired_at'],
      )!,
      lastConnectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_connected_at'],
      ),
    );
  }

  @override
  $PeersTable createAlias(String alias) {
    return $PeersTable(attachedDatabase, alias);
  }
}

class PeerRow extends DataClass implements Insertable<PeerRow> {
  final String deviceId;
  final String? name;

  /// 身份公钥（base64）。
  final String identityPublicKey;
  final int pairedAt;
  final int? lastConnectedAt;
  const PeerRow({
    required this.deviceId,
    this.name,
    required this.identityPublicKey,
    required this.pairedAt,
    this.lastConnectedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['identity_public_key'] = Variable<String>(identityPublicKey);
    map['paired_at'] = Variable<int>(pairedAt);
    if (!nullToAbsent || lastConnectedAt != null) {
      map['last_connected_at'] = Variable<int>(lastConnectedAt);
    }
    return map;
  }

  PeersCompanion toCompanion(bool nullToAbsent) {
    return PeersCompanion(
      deviceId: Value(deviceId),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      identityPublicKey: Value(identityPublicKey),
      pairedAt: Value(pairedAt),
      lastConnectedAt: lastConnectedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnectedAt),
    );
  }

  factory PeerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PeerRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      name: serializer.fromJson<String?>(json['name']),
      identityPublicKey: serializer.fromJson<String>(json['identityPublicKey']),
      pairedAt: serializer.fromJson<int>(json['pairedAt']),
      lastConnectedAt: serializer.fromJson<int?>(json['lastConnectedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'name': serializer.toJson<String?>(name),
      'identityPublicKey': serializer.toJson<String>(identityPublicKey),
      'pairedAt': serializer.toJson<int>(pairedAt),
      'lastConnectedAt': serializer.toJson<int?>(lastConnectedAt),
    };
  }

  PeerRow copyWith({
    String? deviceId,
    Value<String?> name = const Value.absent(),
    String? identityPublicKey,
    int? pairedAt,
    Value<int?> lastConnectedAt = const Value.absent(),
  }) => PeerRow(
    deviceId: deviceId ?? this.deviceId,
    name: name.present ? name.value : this.name,
    identityPublicKey: identityPublicKey ?? this.identityPublicKey,
    pairedAt: pairedAt ?? this.pairedAt,
    lastConnectedAt: lastConnectedAt.present
        ? lastConnectedAt.value
        : this.lastConnectedAt,
  );
  PeerRow copyWithCompanion(PeersCompanion data) {
    return PeerRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      name: data.name.present ? data.name.value : this.name,
      identityPublicKey: data.identityPublicKey.present
          ? data.identityPublicKey.value
          : this.identityPublicKey,
      pairedAt: data.pairedAt.present ? data.pairedAt.value : this.pairedAt,
      lastConnectedAt: data.lastConnectedAt.present
          ? data.lastConnectedAt.value
          : this.lastConnectedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PeerRow(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(deviceId, name, identityPublicKey, pairedAt, lastConnectedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PeerRow &&
          other.deviceId == this.deviceId &&
          other.name == this.name &&
          other.identityPublicKey == this.identityPublicKey &&
          other.pairedAt == this.pairedAt &&
          other.lastConnectedAt == this.lastConnectedAt);
}

class PeersCompanion extends UpdateCompanion<PeerRow> {
  final Value<String> deviceId;
  final Value<String?> name;
  final Value<String> identityPublicKey;
  final Value<int> pairedAt;
  final Value<int?> lastConnectedAt;
  final Value<int> rowid;
  const PeersCompanion({
    this.deviceId = const Value.absent(),
    this.name = const Value.absent(),
    this.identityPublicKey = const Value.absent(),
    this.pairedAt = const Value.absent(),
    this.lastConnectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PeersCompanion.insert({
    required String deviceId,
    this.name = const Value.absent(),
    required String identityPublicKey,
    required int pairedAt,
    this.lastConnectedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       identityPublicKey = Value(identityPublicKey),
       pairedAt = Value(pairedAt);
  static Insertable<PeerRow> custom({
    Expression<String>? deviceId,
    Expression<String>? name,
    Expression<String>? identityPublicKey,
    Expression<int>? pairedAt,
    Expression<int>? lastConnectedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (name != null) 'name': name,
      if (identityPublicKey != null) 'identity_public_key': identityPublicKey,
      if (pairedAt != null) 'paired_at': pairedAt,
      if (lastConnectedAt != null) 'last_connected_at': lastConnectedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PeersCompanion copyWith({
    Value<String>? deviceId,
    Value<String?>? name,
    Value<String>? identityPublicKey,
    Value<int>? pairedAt,
    Value<int?>? lastConnectedAt,
    Value<int>? rowid,
  }) {
    return PeersCompanion(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      identityPublicKey: identityPublicKey ?? this.identityPublicKey,
      pairedAt: pairedAt ?? this.pairedAt,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (identityPublicKey.present) {
      map['identity_public_key'] = Variable<String>(identityPublicKey.value);
    }
    if (pairedAt.present) {
      map['paired_at'] = Variable<int>(pairedAt.value);
    }
    if (lastConnectedAt.present) {
      map['last_connected_at'] = Variable<int>(lastConnectedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PeersCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('name: $name, ')
          ..write('identityPublicKey: $identityPublicKey, ')
          ..write('pairedAt: $pairedAt, ')
          ..write('lastConnectedAt: $lastConnectedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String key;
  final String value;
  const SyncStateRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateRow copyWith({String? key, String? value}) =>
      SyncStateRow(key: key ?? this.key, value: value ?? this.value);
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalIdentityTable extends LocalIdentity
    with TableInfo<$LocalIdentityTable, LocalIdentityRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalIdentityTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privateKeyMeta = const VerificationMeta(
    'privateKey',
  );
  @override
  late final GeneratedColumn<String> privateKey = GeneratedColumn<String>(
    'private_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publicKeyMeta = const VerificationMeta(
    'publicKey',
  );
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
    'public_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    privateKey,
    publicKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_identity';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalIdentityRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('private_key')) {
      context.handle(
        _privateKeyMeta,
        privateKey.isAcceptableOrUnknown(data['private_key']!, _privateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_privateKeyMeta);
    }
    if (data.containsKey('public_key')) {
      context.handle(
        _publicKeyMeta,
        publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  LocalIdentityRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalIdentityRow(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      privateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_key'],
      )!,
      publicKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}public_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalIdentityTable createAlias(String alias) {
    return $LocalIdentityTable(attachedDatabase, alias);
  }
}

class LocalIdentityRow extends DataClass
    implements Insertable<LocalIdentityRow> {
  final String deviceId;
  final String privateKey;
  final String publicKey;
  final int createdAt;
  const LocalIdentityRow({
    required this.deviceId,
    required this.privateKey,
    required this.publicKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['private_key'] = Variable<String>(privateKey);
    map['public_key'] = Variable<String>(publicKey);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  LocalIdentityCompanion toCompanion(bool nullToAbsent) {
    return LocalIdentityCompanion(
      deviceId: Value(deviceId),
      privateKey: Value(privateKey),
      publicKey: Value(publicKey),
      createdAt: Value(createdAt),
    );
  }

  factory LocalIdentityRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalIdentityRow(
      deviceId: serializer.fromJson<String>(json['deviceId']),
      privateKey: serializer.fromJson<String>(json['privateKey']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deviceId': serializer.toJson<String>(deviceId),
      'privateKey': serializer.toJson<String>(privateKey),
      'publicKey': serializer.toJson<String>(publicKey),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  LocalIdentityRow copyWith({
    String? deviceId,
    String? privateKey,
    String? publicKey,
    int? createdAt,
  }) => LocalIdentityRow(
    deviceId: deviceId ?? this.deviceId,
    privateKey: privateKey ?? this.privateKey,
    publicKey: publicKey ?? this.publicKey,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalIdentityRow copyWithCompanion(LocalIdentityCompanion data) {
    return LocalIdentityRow(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      privateKey: data.privateKey.present
          ? data.privateKey.value
          : this.privateKey,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalIdentityRow(')
          ..write('deviceId: $deviceId, ')
          ..write('privateKey: $privateKey, ')
          ..write('publicKey: $publicKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deviceId, privateKey, publicKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalIdentityRow &&
          other.deviceId == this.deviceId &&
          other.privateKey == this.privateKey &&
          other.publicKey == this.publicKey &&
          other.createdAt == this.createdAt);
}

class LocalIdentityCompanion extends UpdateCompanion<LocalIdentityRow> {
  final Value<String> deviceId;
  final Value<String> privateKey;
  final Value<String> publicKey;
  final Value<int> createdAt;
  final Value<int> rowid;
  const LocalIdentityCompanion({
    this.deviceId = const Value.absent(),
    this.privateKey = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalIdentityCompanion.insert({
    required String deviceId,
    required String privateKey,
    required String publicKey,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       privateKey = Value(privateKey),
       publicKey = Value(publicKey),
       createdAt = Value(createdAt);
  static Insertable<LocalIdentityRow> custom({
    Expression<String>? deviceId,
    Expression<String>? privateKey,
    Expression<String>? publicKey,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (privateKey != null) 'private_key': privateKey,
      if (publicKey != null) 'public_key': publicKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalIdentityCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? privateKey,
    Value<String>? publicKey,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalIdentityCompanion(
      deviceId: deviceId ?? this.deviceId,
      privateKey: privateKey ?? this.privateKey,
      publicKey: publicKey ?? this.publicKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (privateKey.present) {
      map['private_key'] = Variable<String>(privateKey.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalIdentityCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('privateKey: $privateKey, ')
          ..write('publicKey: $publicKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $NoteFieldVersionsTable noteFieldVersions =
      $NoteFieldVersionsTable(this);
  late final $ImagesTable images = $ImagesTable(this);
  late final $TombstonesTable tombstones = $TombstonesTable(this);
  late final $PeersTable peers = $PeersTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $LocalIdentityTable localIdentity = $LocalIdentityTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    notes,
    noteFieldVersions,
    images,
    tombstones,
    peers,
    syncState,
    localIdentity,
  ];
}

typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  required String id,
  Value<String?> title,
  Value<String> content,
  Value<String> timeBind,
  Value<int?> startAt,
  Value<int?> endAt,
  Value<String?> color,
  Value<String?> location,
  Value<int?> reminderOffsetMin,
  Value<int?> reminderAt,
  Value<String?> repeatRule,
  Value<String?> createdBy,
  Value<int?> createdAt,
  Value<bool> deleted,
  Value<int?> deletedAt,
  Value<String?> deletedBy,
  Value<int> rowid,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<String> id,
  Value<String?> title,
  Value<String> content,
  Value<String> timeBind,
  Value<int?> startAt,
  Value<int?> endAt,
  Value<String?> color,
  Value<String?> location,
  Value<int?> reminderOffsetMin,
  Value<int?> reminderAt,
  Value<String?> repeatRule,
  Value<String?> createdBy,
  Value<int?> createdAt,
  Value<bool> deleted,
  Value<int?> deletedAt,
  Value<String?> deletedBy,
  Value<int> rowid,
});

final class $$NotesTableReferences
    extends BaseReferences<_$AppDatabase, $NotesTable, NoteRow> {
  $$NotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NoteFieldVersionsTable, List<NoteFieldVersionRow>>
  _noteFieldVersionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.noteFieldVersions,
        aliasName: 'notes__id__note_field_versions__note_id',
      );

  $$NoteFieldVersionsTableProcessedTableManager get noteFieldVersionsRefs {
    final manager = $$NoteFieldVersionsTableTableManager(
      $_db,
      $_db.noteFieldVersions,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _noteFieldVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ImagesTable, List<ImageRow>> _imagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.images,
    aliasName: 'notes__id__images__note_id',
  );

  $$ImagesTableProcessedTableManager get imagesRefs {
    final manager = $$ImagesTableTableManager(
      $_db,
      $_db.images,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_imagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeBind => $composableBuilder(
    column: $table.timeBind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderOffsetMin => $composableBuilder(
    column: $table.reminderOffsetMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> noteFieldVersionsRefs(
    Expression<bool> Function($$NoteFieldVersionsTableFilterComposer f) f,
  ) {
    final $$NoteFieldVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.noteFieldVersions,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NoteFieldVersionsTableFilterComposer(
            $db: $db,
            $table: $db.noteFieldVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> imagesRefs(
    Expression<bool> Function($$ImagesTableFilterComposer f) f,
  ) {
    final $$ImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableFilterComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeBind => $composableBuilder(
    column: $table.timeBind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startAt => $composableBuilder(
    column: $table.startAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endAt => $composableBuilder(
    column: $table.endAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderOffsetMin => $composableBuilder(
    column: $table.reminderOffsetMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get timeBind =>
      $composableBuilder(column: $table.timeBind, builder: (column) => column);

  GeneratedColumn<int> get startAt =>
      $composableBuilder(column: $table.startAt, builder: (column) => column);

  GeneratedColumn<int> get endAt =>
      $composableBuilder(column: $table.endAt, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get reminderOffsetMin => $composableBuilder(
    column: $table.reminderOffsetMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderAt => $composableBuilder(
    column: $table.reminderAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repeatRule => $composableBuilder(
    column: $table.repeatRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedBy =>
      $composableBuilder(column: $table.deletedBy, builder: (column) => column);

  Expression<T> noteFieldVersionsRefs<T extends Object>(
    Expression<T> Function($$NoteFieldVersionsTableAnnotationComposer a) f,
  ) {
    final $$NoteFieldVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.noteFieldVersions,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NoteFieldVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.noteFieldVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> imagesRefs<T extends Object>(
    Expression<T> Function($$ImagesTableAnnotationComposer a) f,
  ) {
    final $$ImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.images,
      getReferencedColumn: (t) => t.noteId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.images,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotesTable,
          NoteRow,
          $$NotesTableFilterComposer,
          $$NotesTableOrderingComposer,
          $$NotesTableAnnotationComposer,
          $$NotesTableCreateCompanionBuilder,
          $$NotesTableUpdateCompanionBuilder,
          (NoteRow, $$NotesTableReferences),
          NoteRow,
          PrefetchHooks Function({bool noteFieldVersionsRefs, bool imagesRefs})
        > {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> timeBind = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> reminderOffsetMin = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deletedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion(
                id: id,
                title: title,
                content: content,
                timeBind: timeBind,
                startAt: startAt,
                endAt: endAt,
                color: color,
                location: location,
                reminderOffsetMin: reminderOffsetMin,
                reminderAt: reminderAt,
                repeatRule: repeatRule,
                createdBy: createdBy,
                createdAt: createdAt,
                deleted: deleted,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> title = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String> timeBind = const Value.absent(),
                Value<int?> startAt = const Value.absent(),
                Value<int?> endAt = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<int?> reminderOffsetMin = const Value.absent(),
                Value<int?> reminderAt = const Value.absent(),
                Value<String?> repeatRule = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deletedBy = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotesCompanion.insert(
                id: id,
                title: title,
                content: content,
                timeBind: timeBind,
                startAt: startAt,
                endAt: endAt,
                color: color,
                location: location,
                reminderOffsetMin: reminderOffsetMin,
                reminderAt: reminderAt,
                repeatRule: repeatRule,
                createdBy: createdBy,
                createdAt: createdAt,
                deleted: deleted,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NotesTable, NoteRow>(table),
                  $$NotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({noteFieldVersionsRefs = false, imagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (noteFieldVersionsRefs) db.noteFieldVersions,
                    if (imagesRefs) db.images,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (noteFieldVersionsRefs)
                        await $_getPrefetchedData<
                          NoteRow,
                          $NotesTable,
                          NoteFieldVersionRow
                        >(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences
                              ._noteFieldVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotesTableReferences(
                                db,
                                table,
                                p0,
                              ).noteFieldVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (imagesRefs)
                        await $_getPrefetchedData<
                          NoteRow,
                          $NotesTable,
                          ImageRow
                        >(
                          currentTable: table,
                          referencedTable: $$NotesTableReferences
                              ._imagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotesTableReferences(db, table, p0).imagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.noteId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotesTable,
      NoteRow,
      $$NotesTableFilterComposer,
      $$NotesTableOrderingComposer,
      $$NotesTableAnnotationComposer,
      $$NotesTableCreateCompanionBuilder,
      $$NotesTableUpdateCompanionBuilder,
      (NoteRow, $$NotesTableReferences),
      NoteRow,
      PrefetchHooks Function({bool noteFieldVersionsRefs, bool imagesRefs})
    >;
typedef $$NoteFieldVersionsTableCreateCompanionBuilder =
    NoteFieldVersionsCompanion Function({
      required String noteId,
      required String field,
      required int lwTs,
      required String lwDevice,
      Value<int> rowid,
    });
typedef $$NoteFieldVersionsTableUpdateCompanionBuilder =
    NoteFieldVersionsCompanion Function({
      Value<String> noteId,
      Value<String> field,
      Value<int> lwTs,
      Value<String> lwDevice,
      Value<int> rowid,
    });

final class $$NoteFieldVersionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NoteFieldVersionsTable,
          NoteFieldVersionRow
        > {
  $$NoteFieldVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotesTable _noteIdTable(_$AppDatabase db) =>
      db.notes.createAlias('note_field_versions__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NoteFieldVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $NoteFieldVersionsTable> {
  $$NoteFieldVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lwTs => $composableBuilder(
    column: $table.lwTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lwDevice => $composableBuilder(
    column: $table.lwDevice,
    builder: (column) => ColumnFilters(column),
  );

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteFieldVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $NoteFieldVersionsTable> {
  $$NoteFieldVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get field => $composableBuilder(
    column: $table.field,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lwTs => $composableBuilder(
    column: $table.lwTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lwDevice => $composableBuilder(
    column: $table.lwDevice,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteFieldVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NoteFieldVersionsTable> {
  $$NoteFieldVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get field =>
      $composableBuilder(column: $table.field, builder: (column) => column);

  GeneratedColumn<int> get lwTs =>
      $composableBuilder(column: $table.lwTs, builder: (column) => column);

  GeneratedColumn<String> get lwDevice =>
      $composableBuilder(column: $table.lwDevice, builder: (column) => column);

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NoteFieldVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NoteFieldVersionsTable,
          NoteFieldVersionRow,
          $$NoteFieldVersionsTableFilterComposer,
          $$NoteFieldVersionsTableOrderingComposer,
          $$NoteFieldVersionsTableAnnotationComposer,
          $$NoteFieldVersionsTableCreateCompanionBuilder,
          $$NoteFieldVersionsTableUpdateCompanionBuilder,
          (NoteFieldVersionRow, $$NoteFieldVersionsTableReferences),
          NoteFieldVersionRow,
          PrefetchHooks Function({bool noteId})
        > {
  $$NoteFieldVersionsTableTableManager(
    _$AppDatabase db,
    $NoteFieldVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NoteFieldVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NoteFieldVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NoteFieldVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> noteId = const Value.absent(),
                Value<String> field = const Value.absent(),
                Value<int> lwTs = const Value.absent(),
                Value<String> lwDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NoteFieldVersionsCompanion(
                noteId: noteId,
                field: field,
                lwTs: lwTs,
                lwDevice: lwDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String noteId,
                required String field,
                required int lwTs,
                required String lwDevice,
                Value<int> rowid = const Value.absent(),
              }) => NoteFieldVersionsCompanion.insert(
                noteId: noteId,
                field: field,
                lwTs: lwTs,
                lwDevice: lwDevice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NoteFieldVersionsTable, NoteFieldVersionRow>(
                    table,
                  ),
                  $$NoteFieldVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.noteId,
                        referencedTable: $$NoteFieldVersionsTableReferences
                            ._noteIdTable(db),
                        referencedColumn: $$NoteFieldVersionsTableReferences
                            ._noteIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NoteFieldVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NoteFieldVersionsTable,
      NoteFieldVersionRow,
      $$NoteFieldVersionsTableFilterComposer,
      $$NoteFieldVersionsTableOrderingComposer,
      $$NoteFieldVersionsTableAnnotationComposer,
      $$NoteFieldVersionsTableCreateCompanionBuilder,
      $$NoteFieldVersionsTableUpdateCompanionBuilder,
      (NoteFieldVersionRow, $$NoteFieldVersionsTableReferences),
      NoteFieldVersionRow,
      PrefetchHooks Function({bool noteId})
    >;
typedef $$ImagesTableCreateCompanionBuilder = ImagesCompanion Function({
  required String id,
  required String noteId,
  required String fileName,
  required String sha256,
  required int size,
  Value<bool> deleted,
  Value<int?> deletedAt,
  Value<String?> deletedBy,
  Value<String> syncStatus,
  Value<String?> chunkBitmap,
  Value<int> totalChunks,
  Value<int> lwTs,
  Value<String> lwDevice,
  Value<int> rowid,
});
typedef $$ImagesTableUpdateCompanionBuilder = ImagesCompanion Function({
  Value<String> id,
  Value<String> noteId,
  Value<String> fileName,
  Value<String> sha256,
  Value<int> size,
  Value<bool> deleted,
  Value<int?> deletedAt,
  Value<String?> deletedBy,
  Value<String> syncStatus,
  Value<String?> chunkBitmap,
  Value<int> totalChunks,
  Value<int> lwTs,
  Value<String> lwDevice,
  Value<int> rowid,
});

final class $$ImagesTableReferences
    extends BaseReferences<_$AppDatabase, $ImagesTable, ImageRow> {
  $$ImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotesTable _noteIdTable(_$AppDatabase db) =>
      db.notes.createAlias('images__note_id__notes__id');

  $$NotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$NotesTableTableManager(
      $_db,
      $_db.notes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ImagesTableFilterComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chunkBitmap => $composableBuilder(
    column: $table.chunkBitmap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lwTs => $composableBuilder(
    column: $table.lwTs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lwDevice => $composableBuilder(
    column: $table.lwDevice,
    builder: (column) => ColumnFilters(column),
  );

  $$NotesTableFilterComposer get noteId {
    final $$NotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableFilterComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableOrderingComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chunkBitmap => $composableBuilder(
    column: $table.chunkBitmap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lwTs => $composableBuilder(
    column: $table.lwTs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lwDevice => $composableBuilder(
    column: $table.lwDevice,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotesTableOrderingComposer get noteId {
    final $$NotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableOrderingComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ImagesTable> {
  $$ImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedBy =>
      $composableBuilder(column: $table.deletedBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chunkBitmap => $composableBuilder(
    column: $table.chunkBitmap,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChunks => $composableBuilder(
    column: $table.totalChunks,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lwTs =>
      $composableBuilder(column: $table.lwTs, builder: (column) => column);

  GeneratedColumn<String> get lwDevice =>
      $composableBuilder(column: $table.lwDevice, builder: (column) => column);

  $$NotesTableAnnotationComposer get noteId {
    final $$NotesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.notes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotesTableAnnotationComposer(
            $db: $db,
            $table: $db.notes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ImagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ImagesTable,
          ImageRow,
          $$ImagesTableFilterComposer,
          $$ImagesTableOrderingComposer,
          $$ImagesTableAnnotationComposer,
          $$ImagesTableCreateCompanionBuilder,
          $$ImagesTableUpdateCompanionBuilder,
          (ImageRow, $$ImagesTableReferences),
          ImageRow,
          PrefetchHooks Function({bool noteId})
        > {
  $$ImagesTableTableManager(_$AppDatabase db, $ImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> noteId = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<int> size = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deletedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> chunkBitmap = const Value.absent(),
                Value<int> totalChunks = const Value.absent(),
                Value<int> lwTs = const Value.absent(),
                Value<String> lwDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion(
                id: id,
                noteId: noteId,
                fileName: fileName,
                sha256: sha256,
                size: size,
                deleted: deleted,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                syncStatus: syncStatus,
                chunkBitmap: chunkBitmap,
                totalChunks: totalChunks,
                lwTs: lwTs,
                lwDevice: lwDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String noteId,
                required String fileName,
                required String sha256,
                required int size,
                Value<bool> deleted = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String?> deletedBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<String?> chunkBitmap = const Value.absent(),
                Value<int> totalChunks = const Value.absent(),
                Value<int> lwTs = const Value.absent(),
                Value<String> lwDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ImagesCompanion.insert(
                id: id,
                noteId: noteId,
                fileName: fileName,
                sha256: sha256,
                size: size,
                deleted: deleted,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                syncStatus: syncStatus,
                chunkBitmap: chunkBitmap,
                totalChunks: totalChunks,
                lwTs: lwTs,
                lwDevice: lwDevice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ImagesTable, ImageRow>(table),
                  $$ImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.noteId,
                        referencedTable: $$ImagesTableReferences._noteIdTable(
                          db,
                        ),
                        referencedColumn: $$ImagesTableReferences
                            ._noteIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ImagesTable,
      ImageRow,
      $$ImagesTableFilterComposer,
      $$ImagesTableOrderingComposer,
      $$ImagesTableAnnotationComposer,
      $$ImagesTableCreateCompanionBuilder,
      $$ImagesTableUpdateCompanionBuilder,
      (ImageRow, $$ImagesTableReferences),
      ImageRow,
      PrefetchHooks Function({bool noteId})
    >;
typedef $$TombstonesTableCreateCompanionBuilder = TombstonesCompanion Function({
  required String recordId,
  required int deletedAt,
  required String deletedBy,
  Value<int?> confirmedAt,
  Value<int> rowid,
});
typedef $$TombstonesTableUpdateCompanionBuilder = TombstonesCompanion Function({
  Value<String> recordId,
  Value<int> deletedAt,
  Value<String> deletedBy,
  Value<int?> confirmedAt,
  Value<int> rowid,
});

class $$TombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedBy => $composableBuilder(
    column: $table.deletedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TombstonesTable> {
  $$TombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedBy =>
      $composableBuilder(column: $table.deletedBy, builder: (column) => column);

  GeneratedColumn<int> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );
}

class $$TombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TombstonesTable,
          TombstoneRow,
          $$TombstonesTableFilterComposer,
          $$TombstonesTableOrderingComposer,
          $$TombstonesTableAnnotationComposer,
          $$TombstonesTableCreateCompanionBuilder,
          $$TombstonesTableUpdateCompanionBuilder,
          (
            TombstoneRow,
            BaseReferences<_$AppDatabase, $TombstonesTable, TombstoneRow>,
          ),
          TombstoneRow,
          PrefetchHooks Function()
        > {
  $$TombstonesTableTableManager(_$AppDatabase db, $TombstonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TombstonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<int> deletedAt = const Value.absent(),
                Value<String> deletedBy = const Value.absent(),
                Value<int?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion(
                recordId: recordId,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required int deletedAt,
                required String deletedBy,
                Value<int?> confirmedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TombstonesCompanion.insert(
                recordId: recordId,
                deletedAt: deletedAt,
                deletedBy: deletedBy,
                confirmedAt: confirmedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TombstonesTable, TombstoneRow>(table),
                  BaseReferences<_$AppDatabase, $TombstonesTable, TombstoneRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TombstonesTable,
      TombstoneRow,
      $$TombstonesTableFilterComposer,
      $$TombstonesTableOrderingComposer,
      $$TombstonesTableAnnotationComposer,
      $$TombstonesTableCreateCompanionBuilder,
      $$TombstonesTableUpdateCompanionBuilder,
      (
        TombstoneRow,
        BaseReferences<_$AppDatabase, $TombstonesTable, TombstoneRow>,
      ),
      TombstoneRow,
      PrefetchHooks Function()
    >;
typedef $$PeersTableCreateCompanionBuilder = PeersCompanion Function({
  required String deviceId,
  Value<String?> name,
  required String identityPublicKey,
  required int pairedAt,
  Value<int?> lastConnectedAt,
  Value<int> rowid,
});
typedef $$PeersTableUpdateCompanionBuilder = PeersCompanion Function({
  Value<String> deviceId,
  Value<String?> name,
  Value<String> identityPublicKey,
  Value<int> pairedAt,
  Value<int?> lastConnectedAt,
  Value<int> rowid,
});

class $$PeersTableFilterComposer extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PeersTableOrderingComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pairedAt => $composableBuilder(
    column: $table.pairedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PeersTableAnnotationComposer
    extends Composer<_$AppDatabase, $PeersTable> {
  $$PeersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get identityPublicKey => $composableBuilder(
    column: $table.identityPublicKey,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pairedAt =>
      $composableBuilder(column: $table.pairedAt, builder: (column) => column);

  GeneratedColumn<int> get lastConnectedAt => $composableBuilder(
    column: $table.lastConnectedAt,
    builder: (column) => column,
  );
}

class $$PeersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PeersTable,
          PeerRow,
          $$PeersTableFilterComposer,
          $$PeersTableOrderingComposer,
          $$PeersTableAnnotationComposer,
          $$PeersTableCreateCompanionBuilder,
          $$PeersTableUpdateCompanionBuilder,
          (PeerRow, BaseReferences<_$AppDatabase, $PeersTable, PeerRow>),
          PeerRow,
          PrefetchHooks Function()
        > {
  $$PeersTableTableManager(_$AppDatabase db, $PeersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PeersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PeersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PeersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> identityPublicKey = const Value.absent(),
                Value<int> pairedAt = const Value.absent(),
                Value<int?> lastConnectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeersCompanion(
                deviceId: deviceId,
                name: name,
                identityPublicKey: identityPublicKey,
                pairedAt: pairedAt,
                lastConnectedAt: lastConnectedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                Value<String?> name = const Value.absent(),
                required String identityPublicKey,
                required int pairedAt,
                Value<int?> lastConnectedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PeersCompanion.insert(
                deviceId: deviceId,
                name: name,
                identityPublicKey: identityPublicKey,
                pairedAt: pairedAt,
                lastConnectedAt: lastConnectedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PeersTable, PeerRow>(table),
                  BaseReferences<_$AppDatabase, $PeersTable, PeerRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PeersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PeersTable,
      PeerRow,
      $$PeersTableFilterComposer,
      $$PeersTableOrderingComposer,
      $$PeersTableAnnotationComposer,
      $$PeersTableCreateCompanionBuilder,
      $$PeersTableUpdateCompanionBuilder,
      (PeerRow, BaseReferences<_$AppDatabase, $PeersTable, PeerRow>),
      PeerRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder = SyncStateCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SyncStateTableUpdateCompanionBuilder = SyncStateCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SyncStateCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateRow>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$LocalIdentityTableCreateCompanionBuilder =
    LocalIdentityCompanion Function({
      required String deviceId,
      required String privateKey,
      required String publicKey,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$LocalIdentityTableUpdateCompanionBuilder =
    LocalIdentityCompanion Function({
      Value<String> deviceId,
      Value<String> privateKey,
      Value<String> publicKey,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$LocalIdentityTableFilterComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalIdentityTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publicKey => $composableBuilder(
    column: $table.publicKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalIdentityTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalIdentityTable> {
  $$LocalIdentityTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get privateKey => $composableBuilder(
    column: $table.privateKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalIdentityTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalIdentityTable,
          LocalIdentityRow,
          $$LocalIdentityTableFilterComposer,
          $$LocalIdentityTableOrderingComposer,
          $$LocalIdentityTableAnnotationComposer,
          $$LocalIdentityTableCreateCompanionBuilder,
          $$LocalIdentityTableUpdateCompanionBuilder,
          (
            LocalIdentityRow,
            BaseReferences<
              _$AppDatabase,
              $LocalIdentityTable,
              LocalIdentityRow
            >,
          ),
          LocalIdentityRow,
          PrefetchHooks Function()
        > {
  $$LocalIdentityTableTableManager(_$AppDatabase db, $LocalIdentityTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalIdentityTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalIdentityTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalIdentityTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deviceId = const Value.absent(),
                Value<String> privateKey = const Value.absent(),
                Value<String> publicKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalIdentityCompanion(
                deviceId: deviceId,
                privateKey: privateKey,
                publicKey: publicKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deviceId,
                required String privateKey,
                required String publicKey,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalIdentityCompanion.insert(
                deviceId: deviceId,
                privateKey: privateKey,
                publicKey: publicKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalIdentityTable, LocalIdentityRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalIdentityTable,
                    LocalIdentityRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalIdentityTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalIdentityTable,
      LocalIdentityRow,
      $$LocalIdentityTableFilterComposer,
      $$LocalIdentityTableOrderingComposer,
      $$LocalIdentityTableAnnotationComposer,
      $$LocalIdentityTableCreateCompanionBuilder,
      $$LocalIdentityTableUpdateCompanionBuilder,
      (
        LocalIdentityRow,
        BaseReferences<_$AppDatabase, $LocalIdentityTable, LocalIdentityRow>,
      ),
      LocalIdentityRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$NoteFieldVersionsTableTableManager get noteFieldVersions =>
      $$NoteFieldVersionsTableTableManager(_db, _db.noteFieldVersions);
  $$ImagesTableTableManager get images =>
      $$ImagesTableTableManager(_db, _db.images);
  $$TombstonesTableTableManager get tombstones =>
      $$TombstonesTableTableManager(_db, _db.tombstones);
  $$PeersTableTableManager get peers =>
      $$PeersTableTableManager(_db, _db.peers);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$LocalIdentityTableTableManager get localIdentity =>
      $$LocalIdentityTableTableManager(_db, _db.localIdentity);
}
