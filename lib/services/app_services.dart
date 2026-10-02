import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/crypto/keys.dart';
import '../core/storage/daos.dart';
import '../core/storage/database.dart';
import '../core/storage/flutter_database.dart';
import '../core/storage/image_files.dart';
import '../core/storage/thumbnails.dart';
import '../core/sync/sync_storage.dart';
import '../core/utils/ids.dart';
import 'note_service.dart';

/// 应用服务装配：打开数据库、加载/创建本地身份、准备目录与存储。
///
/// M3 接入同步引擎时将复用 [identity] 与 [syncStorage]
/// （ADR-020：引擎依赖 DriftSyncStorage 端口，不直接依赖 DAO）。
class AppServices {
  AppServices._({
    required this.db,
    required this.identity,
    required this.images,
    required this.thumbnails,
    required this.syncStorage,
    required this.notes,
  });

  final AppDatabase db;
  final IdentityKeys identity;
  final DiskImageFileStore images;
  final ThumbnailStore thumbnails;
  final DriftSyncStorage syncStorage;
  final NoteService notes;

  /// 打开应用：数据库（openFlutterDatabase）+ 本地身份 + 图片目录。
  static Future<AppServices> open() async {
    final db = await openFlutterDatabase();
    final identity = await _loadOrCreateIdentity(db);
    final docs = await getApplicationDocumentsDirectory();
    final cache = await getTemporaryDirectory();

    final imagesDir =
        Directory('${docs.path}${Platform.pathSeparator}images');
    await imagesDir.create(recursive: true);
    final thumbsDir =
        Directory('${cache.path}${Platform.pathSeparator}thumbnails');
    await thumbsDir.create(recursive: true);

    final imageFiles = DiskImageFileStore(imagesDir);
    final thumbnailStore = ThumbnailStore(thumbsDir);
    final noteService = NoteService(
      db: db,
      identityDeviceId: identity.deviceId,
      files: imageFiles,
      thumbnails: thumbnailStore,
    );

    return AppServices._(
      db: db,
      identity: identity,
      images: imageFiles,
      thumbnails: thumbnailStore,
      syncStorage: DriftSyncStorage(db),
      notes: noteService,
    );
  }

  /// 从 local_identity 表加载本机身份；首次运行则生成并持久化。
  static Future<IdentityKeys> _loadOrCreateIdentity(AppDatabase db) async {
    final dao = LocalIdentityDao(db);
    final existing = await dao.get();
    if (existing != null) {
      return IdentityKeys.fromSeed(
        existing.deviceId,
        base64Decode(existing.privateKey),
      );
    }
    final deviceId = 'dev-${Ids.uuid().substring(0, 8)}';
    final identity = await IdentityKeys.generate(deviceId);
    await dao.save(
      deviceId: identity.deviceId,
      privateKey: base64Encode(identity.seed),
      publicKey: identity.publicKeyBase64,
    );
    return identity;
  }

  Future<void> close() => db.close();
}
