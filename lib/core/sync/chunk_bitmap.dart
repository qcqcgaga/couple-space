/// 分块位图工具：已收/已发块位图以“逗号分隔的 0/1 文本”持久化到 drift，
/// 断点续传时据此计算缺失块。位图长度固定为总块数，第 i 位表示第 i 块。
class ChunkBitmap {
  const ChunkBitmap._();

  /// 解析位图文本为布尔列表；文本缺失、非法或长度不足时按 false 补齐。
  static List<bool> parse(String? text, int total) {
    final result = List<bool>.filled(total < 0 ? 0 : total, false);
    if (text == null || text.isEmpty || total <= 0) return result;
    final parts = text.split(',');
    for (var i = 0; i < parts.length && i < total; i++) {
      result[i] = parts[i] == '1';
    }
    return result;
  }

  static String toText(List<bool> bitmap) =>
      [for (final b in bitmap) b ? '1' : '0'].join(',');

  /// 全 0 位图文本（无任何已收块）。
  static String allZeroText(int total) =>
      total <= 0 ? '' : List.filled(total, '0').join(',');

  /// 全 1 位图文本（所有块已收）。
  static String allOneText(int total) =>
      total <= 0 ? '' : List.filled(total, '1').join(',');

  static bool isComplete(List<bool> bitmap) =>
      bitmap.isNotEmpty && bitmap.every((b) => b);

  /// 位图文本是否为全 1（用于判断对端是否已收齐）。
  static bool textIsComplete(String? text, int total) =>
      isComplete(parse(text, total));

  /// 缺失块序号（升序）；total <= 0 时返回空列表。
  static List<int> missingSequences(String? text, int total) {
    final bitmap = parse(text, total);
    return [for (var i = 0; i < bitmap.length; i++) if (!bitmap[i]) i];
  }

  /// 已收块数。
  static int receivedCount(String? text, int total) =>
      parse(text, total).where((b) => b).length;
}
