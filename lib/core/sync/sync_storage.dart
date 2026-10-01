import '../models/image.dart';
import '../models/note.dart';
import '../storage/daos.dart';
import '../storage/database.dart';
import '../storage/store.dart';
import 'chunk_bitmap.dart';
import 'lww.dart';

/// 同步引擎需要的存储能力（端口）。
///
/// 生产环境用 [DriftSyncStorage]（SQLite）；双进程探针/测试用
/// [MemorySyncStorage]（纯内存），使探针进程不依赖 sqlite3 原生资产，
/// 避免 Windows 上多个 `dart run` 进程争抢同一 DLL。
abstract interface class SyncStorage {
  // 笔记
  Future<Note?> noteById(String id);
  Future<List<Note>> allNotes({bool includeDeleted = false});
  Future<void> saveNote(Note note);
  Future<void> deleteNote(String id, {required String deviceId, required int ts});
  Future<Note> applyRemoteNote(Note remote);

  // 图片
  Future<ImageMeta?> imageById(String id);
  Future<List<ImageMeta>> allImages({bool includeDeleted = false});
  Future<void> upsertImage(ImageMeta image);
  Future<void> markChunkReceived(
    String imageId, {
    required int seq,
    required int chunkSize,
    required int totalChunks,
  });
  Future<void> markImageDone(String imageId, {required int totalChunks});
  Future<void> markImageFailed(String imageId, {required String error});
  Future<void> markImageDeleted(String imageId, {required String deviceId, required int ts});

  // 配对白名单
  Future<bool> isPaired(String deviceId);
  Future<PeerInfo?> findPeer(String deviceId);
  Future<void> upsertPeer({
    required String deviceId,
    required String? name,
    required String identityPublicKey,
  });
  Future<void> touchPeer(String deviceId);

  // 同步状态
  Future<void> setSyncStateInt(String key, int value);

  // 图片传输队列
  Future<void> enqueueTransfer(
    String peerId,
    String imageId, {
    required int chunkSize,
    required int totalChunks,
    String? sentBitmap,
  });
  Future<void> updateTransfer(
    String peerId,
    String imageId, {
    String? status,
    String? sentBitmap,
    int? sentBytes,
    String? error,
  });
  Future<void> removeTransfersForImage(String imageId);
}

/// 已配对设备白名单记录（存储层返回给引擎的身份信息）。
class PeerInfo {
  const PeerInfo({
    required this.deviceId,
    this.name,
    required this.identityPublicKey,
    this.pairedAt = 0,
  });

  final String deviceId;
  final String? name;
  final String identityPublicKey;
  final int pairedAt;
}

/// drift/SQLite 存储实现：适配现有 DAO 与 NoteStore（LWW 合并 + 墓碑）。
class DriftSyncStorage implements SyncStorage {
  DriftSyncStorage(this.db)
      : _notes = NotesDao(db),
        _images = ImagesDao(db),
        _peers = PeersDao(db),
        _syncState = SyncStateDao(db),
        _transfers = ImageTransfersDao(db),
        _store = NoteStore(db);

  final AppDatabase db;
  final NotesDao _notes;
  final ImagesDao _images;
  final PeersDao _peers;
  final SyncStateDao _syncState;
  final ImageTransfersDao _transfers;
  final NoteStore _store;

  @override
  Future<Note?> noteById(String id) => _notes.noteById(id);

  @override
  Future<List<Note>> allNotes({bool includeDeleted = false}) =>
      _notes.allNotes(includeDeleted: includeDeleted);

  @override
  Future<void> saveNote(Note note) => _notes.upsertNote(note);

  @override
  Future<void> deleteNote(String id, {required String deviceId, required int ts}) =>
      _store.delete(id, deviceId: deviceId, ts: ts);

  @override
  Future<Note> applyRemoteNote(Note remote) => _store.applyRemoteNote(remote);

  @override
  Future<ImageMeta?> imageById(String id) => _images.imageById(id);

  @override
  Future<List<ImageMeta>> allImages({bool includeDeleted = false}) =>
      _images.allImages(includeDeleted: includeDeleted);

  @override
  Future<void> upsertImage(ImageMeta image) => _images.upsertImage(image);

  @override
  Future<void> markChunkReceived(
    String imageId, {
    required int seq,
    required int chunkSize,
    required int totalChunks,
  }) =>
      _images.markChunkReceived(
        imageId,
        seq: seq,
        chunkSize: chunkSize,
        totalChunks: totalChunks,
      );

  @override
  Future<void> markImageDone(String imageId, {required int totalChunks}) =>
      _images.markDone(imageId, totalChunks: totalChunks);

  @override
  Future<void> markImageFailed(String imageId, {required String error}) =>
      _images.markFailed(imageId, error: error);

  @override
  Future<void> markImageDeleted(
    String imageId, {
    required String deviceId,
    required int ts,
  }) =>
      _images.markDeleted(imageId, deviceId: deviceId, ts: ts);

  @override
  Future<bool> isPaired(String deviceId) => _peers.isPaired(deviceId);

  @override
  Future<PeerInfo?> findPeer(String deviceId) async {
    final row = await _peers.find(deviceId);
    return row == null
        ? null
        : PeerInfo(
            deviceId: row.deviceId,
            name: row.name,
            identityPublicKey: row.identityPublicKey,
            pairedAt: row.pairedAt,
          );
  }

  @override
  Future<void> upsertPeer({
    required String deviceId,
    required String? name,
    required String identityPublicKey,
  }) =>
      _peers.upsert(PeerRow(
        deviceId: deviceId,
        name: name,
        identityPublicKey: identityPublicKey,
        pairedAt: DateTime.now().millisecondsSinceEpoch,
      ));

  @override
  Future<void> touchPeer(String deviceId) => _peers.touch(deviceId);

  @override
  Future<void> setSyncStateInt(String key, int value) =>
      _syncState.setInt(key, value);

  @override
  Future<void> enqueueTransfer(
    String peerId,
    String imageId, {
    required int chunkSize,
    required int totalChunks,
    String? sentBitmap,
  }) =>
      _transfers.enqueue(
        peerId,
        imageId,
        chunkSize: chunkSize,
        totalChunks: totalChunks,
        sentBitmap: sentBitmap,
      );

  @override
  Future<void> updateTransfer(
    String peerId,
    String imageId, {
    String? status,
    String? sentBitmap,
    int? sentBytes,
    String? error,
  }) =>
      _transfers.updateProgress(
        peerId,
        imageId,
        status: status,
        sentBitmap: sentBitmap,
        sentBytes: sentBytes,
        error: error,
      );

  @override
  Future<void> removeTransfersForImage(String imageId) =>
      _transfers.removeForImage(imageId);
}

/// 纯内存存储实现：用于双进程探针与单元测试，不依赖 sqlite3。
class MemorySyncStorage implements SyncStorage {
  final Map<String, Note> notes = {};
  final Map<String, ImageMeta> images = {};
  final Map<String, PeerInfo> peers = {};
  final Map<String, int> syncState = {};
  final Map<String, _MemoryTransfer> _transfers = {};
  final Map<String, int> tombstones = {};

  static const LwwResolver _resolver = LwwResolver();

  String _transferKey(String peerId, String imageId) => '$peerId\u0000$imageId';

  @override
  Future<Note?> noteById(String id) async => notes[id];

  @override
  Future<List<Note>> allNotes({bool includeDeleted = false}) async =>
      [for (final note in notes.values) if (includeDeleted || !note.deleted) note];

  @override
  Future<void> saveNote(Note note) async {
    notes[note.id] = note;
  }

  @override
  Future<void> deleteNote(String id, {required String deviceId, required int ts}) async {
    final current = notes[id];
    notes[id] = (current ?? Note(id: id)).copyWith(
      deleted: true,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      deletedBy: deviceId,
      fieldVersions: {
        ...?current?.fieldVersions,
        'deleted': FieldVersion(ts, deviceId),
      },
    );
    tombstones[id] = ts;
  }

  @override
  Future<Note> applyRemoteNote(Note remote) async {
    final merged = _resolver.merge(notes[remote.id] ?? Note(id: remote.id), remote);
    notes[merged.id] = merged;
    if (merged.deleted) {
      tombstones[merged.id] =
          merged.deletedAt?.millisecondsSinceEpoch ??
          merged.fieldVersions['deleted']?.ts ??
          DateTime.now().millisecondsSinceEpoch;
    }
    return merged;
  }

  @override
  Future<ImageMeta?> imageById(String id) async => images[id];

  @override
  Future<List<ImageMeta>> allImages({bool includeDeleted = false}) async =>
      [for (final image in images.values) if (includeDeleted || !image.deleted) image];

  @override
  Future<void> upsertImage(ImageMeta image) async {
    images[image.id] = image;
  }

  @override
  Future<void> markChunkReceived(
    String imageId, {
    required int seq,
    required int chunkSize,
    required int totalChunks,
  }) async {
    final current = images[imageId];
    if (current == null) return;
    final bitmap = ChunkBitmap.parse(current.chunkBitmap, totalChunks);
    bitmap[seq] = true;
    final done = ChunkBitmap.isComplete(bitmap);
    images[imageId] = current.copyWith(
      syncStatus: done ? 'done' : 'partial',
      totalChunks: totalChunks,
      chunkSize: chunkSize,
      chunkBitmap: ChunkBitmap.toText(bitmap),
    );
  }

  @override
  Future<void> markImageDone(String imageId, {required int totalChunks}) async {
    final current = images[imageId];
    if (current == null) return;
    images[imageId] = current.copyWith(
      syncStatus: 'done',
      totalChunks: totalChunks,
      chunkBitmap: ChunkBitmap.allOneText(totalChunks),
    );
  }

  @override
  Future<void> markImageFailed(String imageId, {required String error}) async {
    final current = images[imageId];
    if (current == null) return;
    images[imageId] = current.copyWith(
      syncStatus: 'failed',
      chunkBitmap: '',
    );
  }

  @override
  Future<void> markImageDeleted(
    String imageId, {
    required String deviceId,
    required int ts,
  }) async {
    final current = images[imageId];
    if (current == null) return;
    images[imageId] = current.copyWith(
      deleted: true,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      deletedBy: deviceId,
      lwTs: ts,
      lwDevice: deviceId,
    );
  }

  @override
  Future<bool> isPaired(String deviceId) async => peers.containsKey(deviceId);

  @override
  Future<PeerInfo?> findPeer(String deviceId) async => peers[deviceId];

  @override
  Future<void> upsertPeer({
    required String deviceId,
    required String? name,
    required String identityPublicKey,
  }) async {
    peers[deviceId] = PeerInfo(
      deviceId: deviceId,
      name: name,
      identityPublicKey: identityPublicKey,
      pairedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> touchPeer(String deviceId) async {}

  @override
  Future<void> setSyncStateInt(String key, int value) async {
    syncState[key] = value;
  }

  @override
  Future<void> enqueueTransfer(
    String peerId,
    String imageId, {
    required int chunkSize,
    required int totalChunks,
    String? sentBitmap,
  }) async {
    _transfers[_transferKey(peerId, imageId)] = _MemoryTransfer(
      status: 'queued',
      chunkSize: chunkSize,
      totalChunks: totalChunks,
      sentBitmap: sentBitmap,
    );
  }

  @override
  Future<void> updateTransfer(
    String peerId,
    String imageId, {
    String? status,
    String? sentBitmap,
    int? sentBytes,
    String? error,
  }) async {
    final key = _transferKey(peerId, imageId);
    final current = _transfers[key];
    if (current == null) return;
    _transfers[key] = current.copyWith(
      status: status,
      sentBitmap: sentBitmap,
      sentBytes: sentBytes,
      error: error,
    );
  }

  @override
  Future<void> removeTransfersForImage(String imageId) async {
    _transfers.removeWhere((key, _) => key.endsWith('\u0000$imageId'));
  }
}

class _MemoryTransfer {
  const _MemoryTransfer({
    required this.status,
    required this.chunkSize,
    required this.totalChunks,
    this.sentBitmap,
    this.sentBytes = 0,
    this.error,
  });

  final String status;
  final int chunkSize;
  final int totalChunks;
  final String? sentBitmap;
  final int sentBytes;
  final String? error;

  _MemoryTransfer copyWith({
    String? status,
    String? sentBitmap,
    int? sentBytes,
    String? error,
  }) =>
      _MemoryTransfer(
        status: status ?? this.status,
        chunkSize: chunkSize,
        totalChunks: totalChunks,
        sentBitmap: sentBitmap ?? this.sentBitmap,
        sentBytes: sentBytes ?? this.sentBytes,
        error: error ?? this.error,
      );
}
