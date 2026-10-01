import 'dart:async';
import 'dart:typed_data';

import '../transports/transport.dart';
import 'frames.dart';

/// 同步帧线格式编解码。
///
/// 帧 = `[4 字节大端载荷长度][1 字节帧类型][载荷]`；
/// 除 ImageChunk 外载荷为 JSON（UTF-8）。ImageChunk 载荷为
/// `[4 字节 meta 长度][meta JSON][原始数据块]`。
class SyncFrameCodec {
  const SyncFrameCodec._();

  /// 帧头长度：长度（4）+ 类型（1）。
  static const int headerLength = 5;

  /// 单帧载荷上限（64 MB，覆盖大图分块场景）。
  static const int maxPayloadLength = 64 * 1024 * 1024;

  /// ImageChunk 头部长度（meta 长度字段）。
  static const int chunkHeaderLength = 4;

  static Uint8List encode(SyncFrame frame) {
    final Uint8List payload;
    if (frame is ImageChunkFrame) {
      payload = _encodeChunkPayload(frame);
    } else {
      payload = jsonBytes(frameJson(frame));
    }
    final result = Uint8List(headerLength + payload.length);
    final header = ByteData.sublistView(result);
    header.setUint32(0, payload.length);
    result[4] = frame.type.code;
    result.setRange(headerLength, headerLength + payload.length, payload);
    return result;
  }

  static int frameTypeOf(Uint8List frameBytes) {
    if (frameBytes.length < headerLength) {
      throw const FormatException('帧数据不足 5 字节');
    }
    return frameBytes[4];
  }

  static SyncFrame decode(Uint8List frameBytes) {
    if (frameBytes.length < headerLength) {
      throw const FormatException('帧数据不足 5 字节');
    }
    final length = ByteData.sublistView(frameBytes).getUint32(0);
    if (length > maxPayloadLength) {
      throw FormatException('帧载荷超过上限: $length');
    }
    if (frameBytes.length != headerLength + length) {
      throw FormatException('帧长度不一致: 期望 ${headerLength + length}，实际 ${frameBytes.length}');
    }
    final type = SyncFrameType.fromCode(frameBytes[4]);
    final payload = Uint8List.sublistView(frameBytes, headerLength);
    return decodePayload(type, payload);
  }

  static SyncFrame decodePayload(SyncFrameType type, Uint8List payload) {
    if (type == SyncFrameType.imageChunk) {
      return _decodeChunkPayload(payload);
    }
    return frameFromJson(type, jsonFromBytes(payload));
  }

  static Uint8List _encodeChunkPayload(ImageChunkFrame frame) {
    final meta = jsonBytes(frameJson(frame));
    final payload = Uint8List(chunkHeaderLength + meta.length + frame.chunk.length);
    ByteData.sublistView(payload).setUint32(0, meta.length);
    payload.setRange(chunkHeaderLength, chunkHeaderLength + meta.length, meta);
    payload.setRange(
      chunkHeaderLength + meta.length,
      payload.length,
      frame.chunk,
    );
    return payload;
  }

  static ImageChunkFrame _decodeChunkPayload(Uint8List payload) {
    if (payload.length < chunkHeaderLength) {
      throw const FormatException('ImageChunk 载荷不足');
    }
    final metaLength = ByteData.sublistView(payload).getUint32(0);
    if (metaLength > payload.length - chunkHeaderLength) {
      throw const FormatException('ImageChunk meta 长度非法');
    }
    final meta = jsonFromBytes(
      Uint8List.sublistView(payload, chunkHeaderLength, chunkHeaderLength + metaLength),
    );
    final chunk = Uint8List.sublistView(payload, chunkHeaderLength + metaLength);
    return ImageChunkFrame(
      imageId: meta['imageId']! as String,
      seq: meta['seq']! as int,
      total: meta['total']! as int,
      size: meta['size']! as int,
      chunk: Uint8List.fromList(chunk),
    );
  }
}

/// 增量帧解码器：把字节流（TCP/BLE 都可能分包/粘包）还原成完整帧。
class FrameDecoder {
  FrameDecoder({this.maxPayloadLength = SyncFrameCodec.maxPayloadLength});

  final int maxPayloadLength;
  final BytesBuilder _buffer = BytesBuilder(copy: false);

  /// 追加网络字节，返回本次解析出的完整帧。
  List<SyncFrame> add(List<int> data) {
    _buffer.add(data);
    final frames = <SyncFrame>[];
    while (_buffer.length >= SyncFrameCodec.headerLength) {
      final bytes = _buffer.takeBytes();
      final length = ByteData.sublistView(bytes).getUint32(0);
      if (length > maxPayloadLength) {
        throw FormatException('帧载荷超过上限: $length');
      }
      final total = SyncFrameCodec.headerLength + length;
      if (bytes.length < total) {
        // 半帧：把已读内容放回缓冲区等待剩余字节。
        _buffer.add(bytes);
        break;
      }
      if (bytes.length > total) {
        // 一次收到多帧：多余部分放回缓冲区。
        _buffer.add(Uint8List.sublistView(bytes, total));
        frames.add(SyncFrameCodec.decode(Uint8List.sublistView(bytes, 0, total)));
      } else {
        frames.add(SyncFrameCodec.decode(bytes));
      }
    }
    return frames;
  }

  bool get hasPartialData => _buffer.length > 0;

  /// 取走缓冲区内尚未解析成完整帧的字节（供握手→加密切换时移交密文）。
  Uint8List takeRemaining() {
    final bytes = _buffer.takeBytes();
    return Uint8List.fromList(bytes);
  }
}

/// 帧通道：把 [Connection] 的字节流转换为 [SyncFrame] 流。
///
/// TCP/BLE 都可能分包、粘包，由内部 [FrameDecoder] 负责还原完整帧。
/// 加密场景用 EncryptedFrameChannel（先加密整帧再走本通道）。
class FrameChannel {
  FrameChannel(this.connection) : _decoder = FrameDecoder();

  /// 底层可靠字节流。
  final Connection connection;

  final FrameDecoder _decoder;
  final StreamController<SyncFrame> _frames =
      StreamController<SyncFrame>.broadcast();
  bool _listening = false;

  /// 解码后的协议帧流。
  Stream<SyncFrame> get frames => _frames.stream;

  /// 开始监听底层连接（只能调用一次）。
  void start() {
    if (_listening) return;
    _listening = true;
    connection.incoming.listen(
      (chunk) {
        for (final frame in _decoder.add(chunk)) {
          _frames.add(frame);
        }
      },
      onError: (Object e, StackTrace s) => _frames.addError(e, s),
      onDone: () => _frames.close(),
    );
  }

  Future<void> sendFrame(SyncFrame frame) =>
      connection.send(SyncFrameCodec.encode(frame));

  Future<void> close() => connection.close();
}
