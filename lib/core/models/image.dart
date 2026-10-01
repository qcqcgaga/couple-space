/// 图片元数据（与图片文件分离：文件存文件系统，元数据存 drift）。
///
/// 图片以图片 ID 为粒度参与字段级 LWW（添加/删除各自独立），
/// `chunkBitmap` 用于分块传输的断点续传。
class ImageMeta {
  const ImageMeta({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.sha256,
    required this.size,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.syncStatus = 'pending',
    this.chunkBitmap,
    this.totalChunks = 0,
    this.lwTs = 0,
    this.lwDevice = '',
  });

  final String id;
  final String noteId;
  final String fileName;
  final String sha256;
  final int size;

  /// 墓碑标记。
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;

  /// pending / partial / done。
  final String syncStatus;

  /// 已收块位图（0/1 逗号分隔），断点续传用。
  final String? chunkBitmap;

  /// 分块总数。
  final int totalChunks;

  /// 图片级 LWW 版本。
  final int lwTs;
  final String lwDevice;

  ImageMeta copyWith({
    String? noteId,
    String? fileName,
    String? sha256,
    int? size,
    bool? deleted,
    DateTime? deletedAt,
    String? deletedBy,
    String? syncStatus,
    String? chunkBitmap,
    int? totalChunks,
    int? lwTs,
    String? lwDevice,
  }) {
    return ImageMeta(
      id: id,
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
    );
  }
}
