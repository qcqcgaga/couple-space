import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/image.dart';

/// 图片文件存储抽象：原图文件在文件系统，drift 只存元数据（docs/02 §7）。
///
/// 传输层通过本接口按块读写文件；接收方写入的块位置由
/// `seq * chunkSize` 决定，断线重连后从缺失块继续写。
abstract interface class ImageFileStore {
  Future<bool> exists(ImageMeta meta);

  Future<int> size(ImageMeta meta);

  Future<Uint8List> readChunk(ImageMeta meta, int offset, int length);

  Future<void> writeChunk(ImageMeta meta, int offset, Uint8List bytes);

  Future<String> sha256(ImageMeta meta);

  Future<void> delete(ImageMeta meta);
}

/// 磁盘实现：图片文件按 `<id>.<扩展名>` 存放在根目录。
///
/// 扩展名从 fileName 提取并做白名单净化；无法识别时回退 `.bin`。
class DiskImageFileStore implements ImageFileStore {
  DiskImageFileStore(this.root);

  final Directory root;

  static const Set<String> _allowedExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif', 'avif', 'tiff', 'bin',
  };

  File fileFor(ImageMeta meta) {
    final ext = _extensionOf(meta.fileName);
    return File('${root.path}${Platform.pathSeparator}${meta.id}.$ext');
  }

  static String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return 'bin';
    final ext = fileName.substring(dot + 1).toLowerCase();
    return _allowedExtensions.contains(ext) ? ext : 'bin';
  }

  @override
  Future<bool> exists(ImageMeta meta) async => fileFor(meta).existsSync();

  @override
  Future<int> size(ImageMeta meta) async {
    final file = fileFor(meta);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  @override
  Future<Uint8List> readChunk(ImageMeta meta, int offset, int length) async {
    final raf = fileFor(meta).openSync(mode: FileMode.read);
    try {
      raf.setPositionSync(offset);
      final bytes = raf.readSync(length);
      return Uint8List.fromList(bytes);
    } finally {
      raf.closeSync();
    }
  }

  @override
  Future<void> writeChunk(ImageMeta meta, int offset, Uint8List bytes) async {
    final file = fileFor(meta);
    await file.parent.create(recursive: true);
    final raf = file.openSync(mode: FileMode.writeOnlyAppend);
    try {
      raf.setPositionSync(offset);
      raf.writeFromSync(bytes);
    } finally {
      raf.closeSync();
    }
  }

  @override
  Future<String> sha256(ImageMeta meta) async {
    final file = fileFor(meta);
    if (!file.existsSync()) return '';
    final hash = await Sha256().hash(await file.readAsBytes());
    return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  @override
  Future<void> delete(ImageMeta meta) async {
    final file = fileFor(meta);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
