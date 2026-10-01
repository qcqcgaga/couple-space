import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 笔记主表：核心实体「记录/笔记」，时间为可选属性。
///
/// 设计要点（docs/02 §7）：正文为主、标题可选；`deleted` 为墓碑标记，
/// 删除视为对 deleted 字段的一次写入，参与字段级 LWW。
@DataClassName('NoteRow')
class Notes extends Table {
  @override
  String get tableName => 'notes';

  TextColumn get id => text()();

  /// 标题（可选）；缺省时应用层可用正文首行生成展示。
  TextColumn get title => text().nullable()();

  /// 正文主体。
  TextColumn get content => text().withDefault(const Constant(''))();

  /// 时间绑定方式：none / allDay / range。
  TextColumn get timeBind => text().withDefault(const Constant('none'))();

  /// 绑定时间（epoch 毫秒）。allDay 时只记日期。
  IntColumn get startAt => integer().nullable()();
  IntColumn get endAt => integer().nullable()();

  TextColumn get color => text().nullable()();
  TextColumn get location => text().nullable()();
  IntColumn get reminderOffsetMin => integer().nullable()();
  IntColumn get reminderAt => integer().nullable()();

  /// 重复规则（v1 仅预留，不提供界面逻辑）。
  TextColumn get repeatRule => text().nullable()();

  TextColumn get createdBy => text().nullable()();
  IntColumn get createdAt => integer().nullable()();

  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deletedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 字段级版本表：每个可编辑字段独立携带最后写入版本（LWW 决胜）。
@DataClassName('NoteFieldVersionRow')
class NoteFieldVersions extends Table {
  @override
  String get tableName => 'note_field_versions';

  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get field => text()();
  IntColumn get lwTs => integer()();
  TextColumn get lwDevice => text()();

  @override
  Set<Column> get primaryKey => {noteId, field};
}

/// 图片表：图片以图片 ID 为粒度独立 LWW；分块续传位图持久化在这里。
@DataClassName('ImageRow')
class Images extends Table {
  @override
  String get tableName => 'images';

  TextColumn get id => text()();
  TextColumn get noteId => text().references(Notes, #id)();
  TextColumn get fileName => text()();
  TextColumn get sha256 => text()();
  IntColumn get size => integer()();

  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  IntColumn get deletedAt => integer().nullable()();
  TextColumn get deletedBy => text().nullable()();

  /// pending / partial / done。
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// 已收块位图（逗号分隔的 0/1），用于断点续传。
  TextColumn get chunkBitmap => text().nullable()();

  /// 分块总数（续传需要）。
  IntColumn get totalChunks => integer().withDefault(const Constant(0))();

  /// 图片级 LWW 版本（添加/删除各自独立）。
  IntColumn get lwTs => integer().withDefault(const Constant(0))();
  TextColumn get lwDevice => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 墓碑表：记录已删除记录及其删除时间；双方确认后满 30 天可压缩清理。
@DataClassName('TombstoneRow')
class Tombstones extends Table {
  @override
  String get tableName => 'tombstones';

  TextColumn get recordId => text()();
  IntColumn get deletedAt => integer()();
  TextColumn get deletedBy => text()();
  IntColumn get confirmedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {recordId};
}

/// 已配对设备白名单：自动连接只查这张表。
@DataClassName('PeerRow')
class Peers extends Table {
  @override
  String get tableName => 'peers';

  TextColumn get deviceId => text()();
  TextColumn get name => text().nullable()();

  /// 身份公钥（base64）。
  TextColumn get identityPublicKey => text()();

  IntColumn get pairedAt => integer()();
  IntColumn get lastConnectedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// 同步状态：本地设备 ID、最后同步向量、待发送图片队列等键值。
@DataClassName('SyncStateRow')
class SyncState extends Table {
  @override
  String get tableName => 'sync_state';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 本地身份：本机设备 ID 与身份密钥对（X25519，base64 保存）。
@DataClassName('LocalIdentityRow')
class LocalIdentity extends Table {
  @override
  String get tableName => 'local_identity';

  TextColumn get deviceId => text()();
  TextColumn get privateKey => text()();
  TextColumn get publicKey => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {deviceId};
}

/// 应用数据库（drift / SQLite）。
@DriftDatabase(
  tables: [
    Notes,
    NoteFieldVersions,
    Images,
    Tombstones,
    Peers,
    SyncState,
    LocalIdentity,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  /// Flutter 运行时连接：drift_flutter 负责在各平台定位数据库文件
  /// 并加载随应用打包的 SQLite（Android/iOS 由 sqlite3_flutter_libs 提供）。
  factory AppDatabase.open({String dbName = 'couple_space'}) {
    return AppDatabase(driftDatabase(name: dbName));
  }
}
