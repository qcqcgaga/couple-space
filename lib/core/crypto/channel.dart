import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../sync/protocol/codec.dart';
import '../sync/protocol/frames.dart';
import '../sync/transports/transport.dart';

/// 加密字节通道：每条消息独立随机 nonce，ChaCha20-Poly1305 加密后
/// 以 `[4 字节大端长度][nonce+cipherText+mac]` 分帧。
///
/// 密文帧是加密通道自己的线格式；上层协议帧在加密前由
/// [SyncFrameCodec] 编码，保证“加密并认证整帧”。
class EncryptedChannel {
  EncryptedChannel({
    required this.connection,
    required this.sessionKey,
  }) {
    _cipher = Chacha20.poly1305Aead();
  }

  static const int nonceLength = 12;
  static const int macLength = 16;
  static const int headerLength = 4;

  /// 单条密文上限（与协议帧上限一致，含 12 字节 nonce 与 16 字节 MAC）。
  static const int maxMessageLength = SyncFrameCodec.maxPayloadLength +
      SyncFrameCodec.headerLength +
      nonceLength +
      macLength;

  /// 底层可靠字节流。
  final Connection connection;

  /// 会话密钥（HKDF 派生，双方一致）。
  final SecretKey sessionKey;

  late final Cipher _cipher;
  final Random _random = Random.secure();
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  final StreamController<Uint8List> _incoming =
      StreamController<Uint8List>.broadcast();
  bool _listening = false;

  /// 解密后的字节流（单条消息）。
  Stream<List<int>> get incoming => _incoming.stream;

  /// 开始监听底层连接并解密（只能调用一次）。
  void start() {
    if (_listening) return;
    _listening = true;
    connection.incoming.listen(
      _onData,
      onError: (Object e, StackTrace s) {
        _incoming.addError(e, s);
      },
      onDone: () => _incoming.close(),
    );
  }

  Future<void> _onData(List<int> chunk) async {
    _buffer.add(chunk);
    while (_buffer.length >= headerLength) {
      final bytes = _buffer.takeBytes();
      final length = ByteData.sublistView(bytes).getUint32(0);
      if (length > maxMessageLength) {
        _incoming.addError(FormatException('密文帧超过上限: $length'));
        return;
      }
      final total = headerLength + length;
      if (bytes.length < total) {
        _buffer.add(bytes);
        return;
      }
      final body = Uint8List.sublistView(bytes, headerLength, total);
      if (bytes.length > total) {
        _buffer.add(Uint8List.sublistView(bytes, total));
      }
      try {
        final box = SecretBox.fromConcatenation(
          body,
          nonceLength: nonceLength,
          macLength: macLength,
        );
        final plain = await _cipher.decrypt(box, secretKey: sessionKey);
        _incoming.add(Uint8List.fromList(plain));
      } catch (e, s) {
        _incoming.addError(e, s);
        return;
      }
    }
  }

  /// 加密并发送一条消息。
  Future<void> send(List<int> plaintext) async {
    final nonce = _freshNonce();
    final box = await _cipher.encrypt(
      plaintext,
      secretKey: sessionKey,
      nonce: nonce,
    );
    final body = box.concatenation();
    final frame = Uint8List(headerLength + body.length);
    ByteData.sublistView(frame).setUint32(0, body.length);
    frame.setRange(headerLength, frame.length, body);
    await connection.send(frame);
  }

  Future<void> close() => connection.close();

  Uint8List _freshNonce() {
    final nonce = Uint8List(nonceLength);
    for (var i = 0; i < nonceLength; i++) {
      nonce[i] = _random.nextInt(256);
    }
    return nonce;
  }
}

/// 加密帧通道：SyncFrame -> 编码 -> 加密 -> 底层字节流；反向亦然。
///
/// 同步引擎只面向 SyncFrame，不直接接触密文。
class EncryptedFrameChannel {
  EncryptedFrameChannel({
    required Connection connection,
    required SecretKey sessionKey,
  }) : _channel = EncryptedChannel(connection: connection, sessionKey: sessionKey);

  final EncryptedChannel _channel;
  final FrameDecoder _decoder = FrameDecoder();
  final StreamController<SyncFrame> _frames =
      StreamController<SyncFrame>.broadcast();
  bool _listening = false;

  Stream<SyncFrame> get frames => _frames.stream;

  void start() {
    if (_listening) return;
    _listening = true;
    _channel.start();
    _channel.incoming.listen((bytes) {
      for (final frame in _decoder.add(bytes)) {
        _frames.add(frame);
      }
    }, onError: (Object e, StackTrace s) {
      _frames.addError(e, s);
    }, onDone: () {
      _frames.close();
    });
  }

  Future<void> sendFrame(SyncFrame frame) =>
      _channel.send(SyncFrameCodec.encode(frame));

  Future<void> close() => _channel.close();
}
