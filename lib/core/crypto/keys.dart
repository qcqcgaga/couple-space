import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// 身份密钥对（X25519）。
///
/// 私钥以种子形式保存（drift local_identity 表），可随时重建 [SimpleKeyPair]。
/// 身份公钥写入 peers 白名单，用于首次配对与握手校验。
class IdentityKeys {
  IdentityKeys._({
    required this.deviceId,
    required this.seed,
    required this.publicKey,
  });

  final String deviceId;

  /// X25519 私钥种子（32 字节）。
  final Uint8List seed;

  /// 身份公钥（32 字节）。
  final Uint8List publicKey;

  static final X25519 _algorithm = X25519();

  static Future<IdentityKeys> generate(String deviceId) async {
    final keyPair = await _algorithm.newKeyPair();
    return _fromKeyPair(deviceId, keyPair);
  }

  static Future<IdentityKeys> fromSeed(String deviceId, List<int> seed) async {
    final keyPair = await _algorithm.newKeyPairFromSeed(seed);
    return _fromKeyPair(deviceId, keyPair);
  }

  static Future<IdentityKeys> _fromKeyPair(
    String deviceId,
    SimpleKeyPair keyPair,
  ) async {
    final private = await keyPair.extractPrivateKeyBytes();
    final public = await keyPair.extractPublicKey();
    return IdentityKeys._(
      deviceId: deviceId,
      seed: Uint8List.fromList(private),
      publicKey: Uint8List.fromList(public.bytes),
    );
  }

  Future<SimpleKeyPair> get keyPair => _algorithm.newKeyPairFromSeed(seed);

  String get publicKeyBase64 => base64Encode(publicKey);
}

/// 一次连接内的临时 ECDH 会话密钥对（每次连接重新生成）。
class EcdhSession {
  EcdhSession._(this.keyPair, this.publicKey);

  final SimpleKeyPair keyPair;
  final Uint8List publicKey;

  static final X25519 _algorithm = X25519();

  static Future<EcdhSession> generate() async {
    final keyPair = await _algorithm.newKeyPair();
    final public = await keyPair.extractPublicKey();
    return EcdhSession._(keyPair, Uint8List.fromList(public.bytes));
  }

  /// 计算与对端临时公钥的共享密钥。
  Future<SecretKey> sharedSecretWith(List<int> peerPublicKey) {
    return _algorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(peerPublicKey, type: KeyPairType.x25519),
    );
  }
}

/// 会话密钥派生与配对码（SAS）。
///
/// 设计（docs/02 §5）：通道用 X25519 ECDH 协商会话密钥；
/// 首次配对用 6 位配对码作为短认证串防中间人。
class SessionKeys {
  const SessionKeys._();

  static const String _sessionInfoPrefix = 'couple-space/v1/session';
  static const String _pairingInfoPrefix = 'couple-space/v1/pairing';
  static const List<int> _salt = [0x63, 0x73, 0x2d, 0x73, 0x61, 0x6c, 0x74]; // 'cs-salt'

  /// 用 HKDF-SHA256 从 ECDH 共享密钥派生出 32 字节会话密钥。
  ///
  /// 派生输入绑定双方临时公钥，避免密钥被其它会话复用。
  static Future<SecretKey> deriveSessionKey({
    required SecretKey sharedSecret,
    required List<int> ourSessionPublicKey,
    required List<int> peerSessionPublicKey,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final keys = _ordered(ourSessionPublicKey, peerSessionPublicKey);
    final info = <int>[
      ...utf8.encode(_sessionInfoPrefix),
      0,
      ...keys[0],
      0,
      ...keys[1],
    ];
    return hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: _salt,
      info: info,
    );
  }

  /// 计算 6 位配对码：双方用同一 ECDH 共享密钥各自算出相同 SAS。
  static Future<String> pairingCode({
    required SecretKey sharedSecret,
    required List<int> ourIdentityPublicKey,
    required List<int> peerIdentityPublicKey,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 8);
    final keys = _ordered(ourIdentityPublicKey, peerIdentityPublicKey);
    final info = <int>[
      ...utf8.encode(_pairingInfoPrefix),
      0,
      ...keys[0],
      0,
      ...keys[1],
    ];
    final derived = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: _salt,
      info: info,
    );
    final bytes = Uint8List.fromList(await derived.extractBytes());
    // 取后 4 字节（大端）取模 1000000，补齐 6 位。
    final value = ByteData.sublistView(bytes).getUint32(4);
    return (value % 1000000).toString().padLeft(6, '0');
  }

  /// 规范化两个公钥顺序（字节序比较），保证双方派生出相同密钥。
  static List<List<int>> _ordered(List<int> a, List<int> b) {
    final length = a.length < b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      if (a[i] != b[i]) return a[i] < b[i] ? [a, b] : [b, a];
    }
    return a.length <= b.length ? [a, b] : [b, a];
  }
}
