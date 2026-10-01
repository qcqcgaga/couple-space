import 'dart:convert';
import 'dart:typed_data';

import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/sync/protocol/codec.dart';
import 'package:couple_space/core/sync/protocol/frames.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sampleFrames = <SyncFrame>[
    const HelloFrame(
      deviceId: 'deviceA',
      appVersion: '0.1.0',
      protocolVersion: 1,
      identityPublicKey: 'cHVia2V5',
    ),
    const PeerInfoFrame(deviceId: 'deviceA', name: '小明的手机'),
    const AuthFrame(
      deviceId: 'deviceA',
      sessionPublicKey: 'c2Vzc2lvbg==',
      handshakeNonce: 'bm9uY2U=',
    ),
    const PairFrame(
      deviceId: 'deviceA',
      code: '123456',
      identityPublicKey: 'cHVia2V5',
      name: '小明的手机',
    ),
    const VersionMapFrame(
      entries: [
        RecordVersion(
          recordId: 'n1',
          updatedAt: 1700000000000,
          deviceId: 'deviceA',
          deleted: false,
        ),
        RecordVersion(
          recordId: 'n2',
          updatedAt: 1700000001000,
          deviceId: 'deviceB',
          deleted: true,
        ),
      ],
    ),
    NoteDeltaFrame(
      payload: NotePayload(
        note: Note(
          id: 'n1',
          title: '我们的旅行',
          content: '正文：去海边。',
          timeBind: TimeBind.range,
          startAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          endAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
          deleted: false,
          fieldVersions: {
            'title': const FieldVersion(100, 'deviceA'),
            'content': const FieldVersion(200, 'deviceB'),
          },
        ),
      ),
    ),
    const ImageMetaFrame(
      payload: ImagePayload(
        id: 'img1',
        noteId: 'n1',
        fileName: 'photo.jpg',
        sha256: 'sha256hash',
        size: 1024,
        lwTs: 100,
        lwDevice: 'deviceA',
      ),
    ),
    const AckFrame(forType: SyncFrameType.versionMap, ok: true, message: '收到'),
    const ErrorFrame(code: 'bad_frame', message: '无法解析', fatal: false),
    const ByeFrame(reason: '退出'),
  ];

  group('SyncFrameCodec 往返', () {
    for (final frame in sampleFrames) {
      test('${frame.type.name} 编码后能原样解码', () {
        final bytes = SyncFrameCodec.encode(frame);
        expect(bytes[4], frame.type.code);
        final decoded = SyncFrameCodec.decode(bytes);
        expect(decoded.type, frame.type);
        _expectFrameEqual(decoded, frame);
      });
    }
  });

  group('ImageChunkFrame', () {
    test('二进制载荷保留 meta 与原始数据块', () {
      final chunk = Uint8List.fromList(List.generate(256, (i) => i));
      final frame = ImageChunkFrame(
        imageId: 'img1',
        seq: 2,
        total: 8,
        size: 2048,
        chunk: chunk,
      );

      final bytes = SyncFrameCodec.encode(frame);
      expect(bytes[4], SyncFrameType.imageChunk.code);

      final payload = Uint8List.sublistView(bytes, SyncFrameCodec.headerLength);
      final metaLength = ByteData.sublistView(payload).getUint32(0);
      final meta = jsonDecode(utf8.decode(Uint8List.sublistView(
        payload,
        SyncFrameCodec.chunkHeaderLength,
        SyncFrameCodec.chunkHeaderLength + metaLength,
      ))) as Map<String, Object?>;
      expect(meta['imageId'], 'img1');
      expect(meta['seq'], 2);
      expect(meta['total'], 8);

      final decoded = SyncFrameCodec.decode(bytes) as ImageChunkFrame;
      expect(decoded.chunk, chunk);
      expect(decoded.size, 2048);
    });

    test('空数据块也支持', () {
      final frame = ImageChunkFrame(
        imageId: 'img1',
        seq: 0,
        total: 1,
        size: 0,
        chunk: Uint8List(0),
      );
      final decoded = SyncFrameCodec.decode(SyncFrameCodec.encode(frame));
      expect((decoded as ImageChunkFrame).chunk, isEmpty);
    });
  });

  group('FrameDecoder 增量解码', () {
    test('分包/粘包都能还原为完整帧', () {
      final hello = SyncFrameCodec.encode(
        const HelloFrame(
          deviceId: 'deviceA',
          appVersion: '0.1.0',
          protocolVersion: 1,
          identityPublicKey: 'cHVia2V5',
        ),
      );
      final bye = SyncFrameCodec.encode(const ByeFrame(reason: '再见'));
      final all = Uint8List.fromList([...hello, ...bye]);

      final decoder = FrameDecoder();
      final frames = <SyncFrame>[];
      // 逐字节喂入，模拟最极端的分包。
      for (var i = 0; i < all.length; i++) {
        frames.addAll(decoder.add([all[i]]));
      }
      expect(frames.length, 2);
      expect(frames[0], isA<HelloFrame>());
      expect(frames[1], isA<ByeFrame>());
    });

    test('一次喂入多帧', () {
      final a = SyncFrameCodec.encode(const AckFrame());
      final b = SyncFrameCodec.encode(const AckFrame());
      final frames = FrameDecoder().add([...a, ...b]);
      expect(frames.length, 2);
    });

    test('载荷超过上限抛出 FormatException', () {
      final decoder = FrameDecoder(maxPayloadLength: 16);
      final big = Uint8List(32);
      ByteData.sublistView(big).setUint32(0, 32);
      expect(() => decoder.add(big), throwsFormatException);
    });
  });
}

void _expectFrameEqual(SyncFrame decoded, SyncFrame original) {
  switch (original) {
    case HelloFrame():
      final d = decoded as HelloFrame;
      expect(d.deviceId, original.deviceId);
      expect(d.appVersion, original.appVersion);
      expect(d.protocolVersion, original.protocolVersion);
      expect(d.identityPublicKey, original.identityPublicKey);
    case PeerInfoFrame():
      final d = decoded as PeerInfoFrame;
      expect(d.deviceId, original.deviceId);
      expect(d.name, original.name);
    case AuthFrame():
      final d = decoded as AuthFrame;
      expect(d.deviceId, original.deviceId);
      expect(d.sessionPublicKey, original.sessionPublicKey);
      expect(d.handshakeNonce, original.handshakeNonce);
    case PairFrame():
      final d = decoded as PairFrame;
      expect(d.deviceId, original.deviceId);
      expect(d.code, original.code);
      expect(d.identityPublicKey, original.identityPublicKey);
    case VersionMapFrame():
      final d = decoded as VersionMapFrame;
      expect(d.entries.length, original.entries.length);
      for (var i = 0; i < original.entries.length; i++) {
        expect(d.entries[i].recordId, original.entries[i].recordId);
        expect(d.entries[i].updatedAt, original.entries[i].updatedAt);
        expect(d.entries[i].deviceId, original.entries[i].deviceId);
        expect(d.entries[i].deleted, original.entries[i].deleted);
      }
    case NoteDeltaFrame():
      final d = decoded as NoteDeltaFrame;
      expect(d.note.id, original.note.id);
      expect(d.note.title, original.note.title);
      expect(d.note.content, original.note.content);
      expect(d.note.timeBind, original.note.timeBind);
      expect(d.note.fieldVersions['title'], const FieldVersion(100, 'deviceA'));
    case ImageMetaFrame():
      final d = decoded as ImageMetaFrame;
      expect(d.payload.id, original.payload.id);
      expect(d.payload.noteId, original.payload.noteId);
      expect(d.payload.sha256, original.payload.sha256);
      expect(d.payload.size, original.payload.size);
      expect(d.payload.lwTs, original.payload.lwTs);
    case AckFrame():
      final d = decoded as AckFrame;
      expect(d.ok, original.ok);
      expect(d.forType, original.forType);
      expect(d.message, original.message);
    case ErrorFrame():
      final d = decoded as ErrorFrame;
      expect(d.code, original.code);
      expect(d.message, original.message);
      expect(d.fatal, original.fatal);
    case ByeFrame():
      final d = decoded as ByeFrame;
      expect(d.reason, original.reason);
    case ImageChunkFrame():
      final d = decoded as ImageChunkFrame;
      expect(d.imageId, original.imageId);
      expect(d.seq, original.seq);
      expect(d.total, original.total);
      expect(d.chunk, original.chunk);
  }
}
