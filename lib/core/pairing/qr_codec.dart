/// 二维码配对数据与编解码（docs/02 §5：首次配对用二维码/配对码建立信任）。
///
/// 二维码内容为本机配对信息：设备 ID、昵称与身份公钥（base64）。
/// 扫码方据此锁定对端身份（out-of-band），连接建立后仍需比对 6 位
/// 配对码（SAS）完成确认，防止中间人（ADR-030）。
class PairQrData {
  const PairQrData({
    required this.deviceId,
    required this.identityPublicKey,
    this.name = '',
  });

  final String deviceId;

  /// 昵称（可空，展示用）。
  final String name;

  /// X25519 身份公钥（base64，与 Hello 帧一致）。
  final String identityPublicKey;
}

/// `couple-space://pair?deviceId=...&name=...&key=...` 编码与解码。
class PairQrCodec {
  const PairQrCodec._();

  static const String scheme = 'couple-space';
  static const String host = 'pair';
  static const String queryKey = 'key';

  /// 生成二维码文本（严格编码，公钥中的 + / = 等字符安全）。
  static String encode(PairQrData data) {
    final query = Uri(
      scheme: scheme,
      host: host,
      queryParameters: {
        'deviceId': data.deviceId,
        if (data.name.isNotEmpty) 'name': data.name,
        queryKey: data.identityPublicKey,
      },
    );
    return query.toString();
  }

  /// 解析二维码文本；格式不合法或缺少必填字段时抛 [FormatException]。
  static PairQrData decode(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    if (uri == null ||
        uri.scheme != scheme ||
        uri.host != host ||
        uri.queryParameters.isEmpty) {
      throw const FormatException('不是有效的配对二维码内容');
    }
    final deviceId = uri.queryParameters['deviceId'];
    final identityPublicKey = uri.queryParameters[queryKey];
    if (deviceId == null || deviceId.isEmpty) {
      throw const FormatException('二维码缺少设备 ID');
    }
    if (identityPublicKey == null || identityPublicKey.isEmpty) {
      throw const FormatException('二维码缺少身份公钥');
    }
    return PairQrData(
      deviceId: deviceId,
      identityPublicKey: identityPublicKey,
      name: uri.queryParameters['name'] ?? '',
    );
  }
}
