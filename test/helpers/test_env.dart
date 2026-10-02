import 'dart:io';

import 'package:couple_space/core/storage/database.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:couple_space/core/storage/thumbnails.dart';
import 'package:couple_space/services/note_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:image/image.dart' as img;

/// 测试环境：内存 drift 数据库 + 临时目录（原图/缩略图）+ NoteService。
class TestEnv {
  TestEnv({required this.db, required this.temp, required this.service});

  final AppDatabase db;
  final Directory temp;
  final NoteService service;
  bool _dbClosed = false;

  static Future<TestEnv> create({
    String deviceId = 'test-device',
    bool memoryImporter = false,
  }) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = AppDatabase(NativeDatabase.memory());
    final temp =
        await Directory.systemTemp.createTemp('couple_space_test_');
    final imagesDir =
        Directory('${temp.path}${Platform.pathSeparator}images');
    await imagesDir.create(recursive: true);
    final thumbsDir =
        Directory('${temp.path}${Platform.pathSeparator}thumbnails');
    await thumbsDir.create(recursive: true);

    final service = NoteService(
      db: db,
      identityDeviceId: deviceId,
      files: DiskImageFileStore(imagesDir),
      thumbnails: ThumbnailStore(thumbsDir),
      importer: memoryImporter ? const MemoryLocalImageImporter() : null,
    );
    return TestEnv(db: db, temp: temp, service: service);
  }

  /// 生成一张真实小 PNG，作为「已选图片」的源文件。
  Future<File> writePng({String name = 'photo.png'}) async {
    // 用 image 包编码一张 3x2 的粉色小图，确保缩略图链路可解码。
    final source = img.Image(width: 3, height: 2);
    img.fill(source, color: img.ColorRgb8(240, 140, 164));
    final bytes = img.encodePng(source);
    final file = File('${temp.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> dispose() async {
    if (!_dbClosed) {
      _dbClosed = true;
      await db.close();
    }
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  }

  /// 在测试体内关闭数据库（drift 的流清理依赖假异步仍存活）。
  Future<void> closeDatabase() async {
    if (_dbClosed) return;
    _dbClosed = true;
    await db.close();
  }
}
