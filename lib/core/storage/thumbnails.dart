import 'dart:io';

import 'package:image/image.dart' as img;

/// 缩略图缓存：从原图文件生成小尺寸 JPEG 缩略图，供列表/日历/编辑页展示。
///
/// 设计（docs/01 §6.3、ADR-024）：原图完整保留、不压缩；缩略图只用于
/// 展示，生成失败（非图片格式或文件尚未同步完整）时返回 null，由 UI
/// 展示占位图。
class ThumbnailStore {
  ThumbnailStore(this.root);

  /// 缩略图缓存根目录（应用 cache 目录下）。
  final Directory root;

  /// 默认缩略图最大边长（像素）。
  static const int defaultMaxSize = 480;

  File fileFor(String imageId) {
    return File('${root.path}${Platform.pathSeparator}${imageId}_thumb.jpg');
  }

  /// 确保缩略图存在并返回；原图缺失或无法解码时返回 null。
  Future<File?> ensureThumbnail({
    required String imageId,
    required File sourceFile,
    int maxSize = defaultMaxSize,
  }) async {
    final target = fileFor(imageId);
    if (target.existsSync()) return target;
    if (!sourceFile.existsSync()) return null;
    await root.create(recursive: true);
    final sourceBytes = await sourceFile.readAsBytes();
    final decoded = img.decodeImage(sourceBytes);
    if (decoded == null) return null;

    // 只传一侧尺寸：image 包会按比例缩放另一侧。
    final thumb = (decoded.width > maxSize || decoded.height > maxSize)
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxSize : null,
            height: decoded.height > decoded.width ? maxSize : null,
          )
        : decoded;
    final jpg = img.encodeJpg(thumb, quality: 82);
    await target.writeAsBytes(jpg, flush: true);
    return target;
  }

  /// 删除某个图片的缩略图缓存。
  Future<void> remove(String imageId) async {
    final file = fileFor(imageId);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
