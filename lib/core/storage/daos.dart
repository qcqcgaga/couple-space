import 'package:drift/drift.dart';

import 'dart:async';

import '../models/image.dart';
import '../models/note.dart';
import '../models/note_edit.dart';
import '../sync/chunk_bitmap.dart';
import 'database.dart';
import 'mappers.dart';

/// 笔记 DAO：CRUD、字段版本读写、墓碑。
class NotesDao {
  NotesDao(this.db);

  final AppDatabase db;

  Future<Note?> noteById(String id) async {
    final row = await (db.select(db.notes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final versions = await fieldVersionsFor(id);
    return NoteMapper.toModel(row, versions);
  }

  Future<List<Note>> allNotes({bool includeDeleted = false}) async {
    final query = db.select(db.notes);
    if (!includeDeleted) {
      query.where((t) => t.deleted.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.createdAt),
    ]);
    final rows = await query.get();
    final result = <Note>[];
    for (final row in rows) {
      final versions = await fieldVersionsFor(row.id);
      result.add(NoteMapper.toModel(row, versions));
    }
    return result;
  }

  /// 响应式监听全部可见笔记（含字段版本与图片变化的刷新）。
  ///
  /// notes / note_field_versions / images 任一表变化都会重新查询并发出
  /// 最新列表，供笔记列表与日历等主视图消费。
  Stream<List<Note>> watchNotes({bool includeDeleted = false}) {
    final controller = StreamController<List<Note>>();
    late final StreamSubscription<List<NoteRow>> noteSub;
    late final StreamSubscription<List<NoteFieldVersionRow>> versionSub;
    late final StreamSubscription<List<ImageRow>> imageSub;

    Future<void> reload() async {
      try {
        final notes = await allNotes(includeDeleted: includeDeleted);
        if (!controller.isClosed) {
          controller.add(notes);
        }
      } catch (error) {
        if (!controller.isClosed) {
          controller.addError(error);
        }
      }
    }

    noteSub = db.select(db.notes).watch().listen((_) => reload());
    versionSub = db.select(db.noteFieldVersions).watch().listen((_) => reload());
    imageSub = db.select(db.images).watch().listen((_) => reload());

    controller.onCancel = () async {
      await noteSub.cancel();
      await versionSub.cancel();
      await imageSub.cancel();
    };

    // 主动触发一次初始加载（watch 的首帧可能先于订阅者到达）。
    unawaited(reload());
    return controller.stream;
  }

  /// 取某个同步时间点之后有更新的笔记（含已删除），用于增量同步。
  Future<List<Note>> notesChangedSince(int sinceTs) async {
    final rows = await db.select(db.notes).get();
    final result = <Note>[];
    for (final row in rows) {
      final versions = await fieldVersionsFor(row.id);
      final note = NoteMapper.toModel(row, versions);
      if (NoteVersions.lastUpdatedAt(note) > sinceTs) {
        result.add(note);
      }
    }
    return result;
  }

  Future<Map<String, FieldVersion>> fieldVersionsFor(String noteId) async {
    final rows = await (db.select(db.noteFieldVersions)
          ..where((t) => t.noteId.equals(noteId)))
        .get();
    return {
      for (final row in rows) row.field: FieldVersion(row.lwTs, row.lwDevice),
    };
  }

  /// 整条覆盖写入（笔记行 + 字段版本），供本地保存与 LWW 合并结果落库。
  Future<void> upsertNote(Note note) async {
    await db.transaction(() async {
      await db.into(db.notes).insertOnConflictUpdate(NoteMapper.toRow(note));
      await (db.delete(db.noteFieldVersions)
            ..where((t) => t.noteId.equals(note.id)))
          .go();
      final versionRows = NoteMapper.versionRows(note);
      if (versionRows.isNotEmpty) {
        await db.batch((b) {
          b.insertAllOnConflictUpdate(db.noteFieldVersions, versionRows);
        });
      }
    });
  }

  Future<void> upsertNotes(Iterable<Note> notes) async {
    await db.transaction(() async {
      for (final note in notes) {
        await upsertNote(note);
      }
    });
  }

  /// 记录删除（墓碑）：删除视为一次字段写入，同样走 LWW。
  Future<void> markDeleted(
    String id, {
    required String deviceId,
    required int ts,
  }) async {
    final current = await noteById(id);
    final deleted = (current ?? Note(id: id)).copyWith(
      deleted: true,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      deletedBy: deviceId,
      fieldVersions: {...?current?.fieldVersions, 'deleted': FieldVersion(ts, deviceId)},
    );
    await upsertNote(deleted);
  }
}

/// 图片 DAO：元数据 CRUD + 续传位图更新。
class ImagesDao {
  ImagesDao(this.db);

  final AppDatabase db;

  Future<ImageMeta?> imageById(String id) async {
    final row = await (db.select(db.images)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : ImageMapper.toModel(row);
  }

  Future<List<ImageMeta>> allImages({bool includeDeleted = false}) async {
    final query = db.select(db.images);
    if (!includeDeleted) {
      query.where((t) => t.deleted.equals(false));
    }
    final rows = await query.get();
    return [for (final row in rows) ImageMapper.toModel(row)];
  }

  Future<List<ImageMeta>> imagesForNote(String noteId) async {
    final rows = await (db.select(db.images)..where((t) => t.noteId.equals(noteId)))
        .get();
    return [for (final row in rows) ImageMapper.toModel(row)];
  }

  Future<List<ImageMeta>> imagesChangedSince(int sinceTs) async {
    final rows = await db.select(db.images).get();
    return [
      for (final row in rows)
        if (row.lwTs > sinceTs) ImageMapper.toModel(row),
    ];
  }

  Future<void> upsertImage(ImageMeta image) async {
    await db.into(db.images).insertOnConflictUpdate(ImageMapper.toRow(image));
  }

  Future<void> updateChunkProgress(
    String imageId, {
    required String status,
    required int totalChunks,
    String? chunkBitmap,
    int? chunkSize,
  }) async {
    await (db.update(db.images)..where((t) => t.id.equals(imageId))).write(
      ImagesCompanion(
        syncStatus: Value(status),
        totalChunks: Value(totalChunks),
        chunkBitmap: Value(chunkBitmap),
        chunkSize: chunkSize == null ? const Value.absent() : Value(chunkSize),
      ),
    );
  }

  /// 标记某一块已收：更新位图与分块配置，供断点续传。
  Future<void> markChunkReceived(
    String imageId, {
    required int seq,
    required int chunkSize,
    required int totalChunks,
  }) async {
    final row = await (db.select(db.images)..where((t) => t.id.equals(imageId)))
        .getSingleOrNull();
    if (row == null) return;
    final bitmap = ChunkBitmap.parse(row.chunkBitmap, totalChunks);
    bitmap[seq] = true;
    final done = ChunkBitmap.isComplete(bitmap);
    await (db.update(db.images)..where((t) => t.id.equals(imageId))).write(
      ImagesCompanion(
        syncStatus: Value(done ? 'done' : 'partial'),
        totalChunks: Value(totalChunks),
        chunkSize: Value(chunkSize),
        chunkBitmap: Value(ChunkBitmap.toText(bitmap)),
      ),
    );
  }

  Future<void> markDone(String imageId, {required int totalChunks}) async {
    await (db.update(db.images)..where((t) => t.id.equals(imageId))).write(
      ImagesCompanion(
        syncStatus: const Value('done'),
        totalChunks: Value(totalChunks),
        chunkBitmap: Value(ChunkBitmap.allOneText(totalChunks)),
      ),
    );
  }

  Future<void> markFailed(String imageId, {required String error}) async {
    await (db.update(db.images)..where((t) => t.id.equals(imageId))).write(
      ImagesCompanion(
        syncStatus: const Value('failed'),
        chunkBitmap: const Value(null),
      ),
    );
  }

  Future<void> markDeleted(
    String imageId, {
    required String deviceId,
    required int ts,
  }) async {
    await (db.update(db.images)..where((t) => t.id.equals(imageId))).write(
      ImagesCompanion(
        deleted: const Value(true),
        deletedAt: Value(ts),
        deletedBy: Value(deviceId),
        lwTs: Value(ts),
        lwDevice: Value(deviceId),
      ),
    );
  }
}

/// 图片传输队列 DAO：待发送图片按（对端, 图片）持久化。
class ImageTransfersDao {
  ImageTransfersDao(this.db);

  final AppDatabase db;

  Future<ImageTransferRow?> find(String peerId, String imageId) async {
    return (db.select(db.imageTransfers)
          ..where((t) => t.peerId.equals(peerId) & t.imageId.equals(imageId)))
        .getSingleOrNull();
  }

  Future<List<ImageTransferRow>> pendingFor(String peerId) async {
    return (db.select(db.imageTransfers)
          ..where((t) => t.peerId.equals(peerId) & t.status.isIn(['queued', 'transferring'])))
        .get();
  }

  Future<List<ImageTransferRow>> allPending() async {
    return (db.select(db.imageTransfers)
          ..where((t) => t.status.isIn(['queued', 'transferring'])))
        .get();
  }

  Future<void> enqueue(
    String peerId,
    String imageId, {
    required int chunkSize,
    required int totalChunks,
    String? sentBitmap,
  }) async {
    await db.into(db.imageTransfers).insertOnConflictUpdate(
          ImageTransfersCompanion(
            peerId: Value(peerId),
            imageId: Value(imageId),
            status: const Value('queued'),
            chunkSize: Value(chunkSize),
            totalChunks: Value(totalChunks),
            sentBitmap: Value(sentBitmap),
            sentBytes: const Value(0),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> updateProgress(
    String peerId,
    String imageId, {
    String? status,
    String? sentBitmap,
    int? sentBytes,
    String? error,
  }) async {
    await (db.update(db.imageTransfers)
          ..where((t) => t.peerId.equals(peerId) & t.imageId.equals(imageId)))
        .write(
          ImageTransfersCompanion(
            status: status == null ? const Value.absent() : Value(status),
            sentBitmap: sentBitmap == null ? const Value.absent() : Value(sentBitmap),
            sentBytes: sentBytes == null ? const Value.absent() : Value(sentBytes),
            error: error == null ? const Value.absent() : Value(error),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
  }

  Future<void> remove(String peerId, String imageId) async {
    await (db.delete(db.imageTransfers)
          ..where((t) => t.peerId.equals(peerId) & t.imageId.equals(imageId)))
        .go();
  }

  Future<void> removeForImage(String imageId) async {
    await (db.delete(db.imageTransfers)..where((t) => t.imageId.equals(imageId)))
        .go();
  }
}

/// 墓碑 DAO：压缩清理（30 天且双方确认）。
class TombstonesDao {
  TombstonesDao(this.db);

  final AppDatabase db;

  static const int retentionDays = 30;

  Future<void> put(String recordId, {required int deletedAt, required String deletedBy}) async {
    await db.into(db.tombstones).insertOnConflictUpdate(
      TombstonesCompanion(
        recordId: Value(recordId),
        deletedAt: Value(deletedAt),
        deletedBy: Value(deletedBy),
      ),
    );
  }

  Future<void> confirm(String recordId) async {
    await (db.update(db.tombstones)..where((t) => t.recordId.equals(recordId))).write(
      TombstonesCompanion(confirmedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<List<TombstoneRow>> all() => db.select(db.tombstones).get();

  /// 清理可压缩的墓碑：双方确认且距今超过 30 天。
  Future<int> purgeExpired() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - retentionDays * Duration.millisecondsPerDay;
    final expired = await (db.select(db.tombstones)
          ..where((t) => t.confirmedAt.isNotNull() & t.confirmedAt.isSmallerThanValue(cutoff)))
        .get();
    if (expired.isEmpty) return 0;
    await db.transaction(() async {
      for (final row in expired) {
        await (db.delete(db.tombstones)..where((t) => t.recordId.equals(row.recordId))).go();
        await (db.delete(db.notes)..where((t) => t.id.equals(row.recordId))).go();
        await (db.delete(db.images)..where((t) => t.noteId.equals(row.recordId))).go();
      }
    });
    return expired.length;
  }
}

/// 已配对设备白名单 DAO。
class PeersDao {
  PeersDao(this.db);

  final AppDatabase db;

  Future<PeerRow?> find(String deviceId) async {
    return (db.select(db.peers)..where((t) => t.deviceId.equals(deviceId)))
        .getSingleOrNull();
  }

  Future<List<PeerRow>> list() => db.select(db.peers).get();

  Future<bool> isPaired(String deviceId) async => await find(deviceId) != null;

  Future<void> upsert(PeerRow row) async {
    await db.into(db.peers).insertOnConflictUpdate(row);
  }

  Future<void> touch(String deviceId) async {
    await (db.update(db.peers)..where((t) => t.deviceId.equals(deviceId))).write(
      PeersCompanion(lastConnectedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<void> remove(String deviceId) async {
    await (db.delete(db.peers)..where((t) => t.deviceId.equals(deviceId))).go();
  }
}

/// 同步状态 DAO（键值）。
class SyncStateDao {
  SyncStateDao(this.db);

  final AppDatabase db;

  Future<String?> get(String key) async {
    final row = await (db.select(db.syncState)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) async {
    await db.into(db.syncState).insertOnConflictUpdate(
      SyncStateCompanion(key: Value(key), value: Value(value)),
    );
  }

  Future<int?> getInt(String key) async {
    final value = await get(key);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> setInt(String key, int value) => set(key, value.toString());

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final value = await get(key);
    return value == null ? fallback : value == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value.toString());
}

/// 本地身份 DAO：本机设备 ID 与身份密钥对。
class LocalIdentityDao {
  LocalIdentityDao(this.db);

  final AppDatabase db;

  Future<LocalIdentityRow?> get() async {
    return (db.select(db.localIdentity)).getSingleOrNull();
  }

  Future<void> save({
    required String deviceId,
    required String privateKey,
    required String publicKey,
  }) async {
    await db.into(db.localIdentity).insertOnConflictUpdate(
      LocalIdentityCompanion(
        deviceId: Value(deviceId),
        privateKey: Value(privateKey),
        publicKey: Value(publicKey),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
