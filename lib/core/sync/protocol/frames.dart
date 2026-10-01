import 'dart:convert';
import 'dart:typed_data';

import '../../models/note.dart';

/// 帧类型：线格式为 `[4 字节大端长度][1 字节类型][载荷]`。
///
/// 对应 docs/02 §4.3 的消息帧草案。除 [ImageChunkFrame] 的载荷是
/// “二进制头 + 原始数据块”外，其余帧载荷均为 JSON。
enum SyncFrameType {
  hello(1),
  peerInfo(2),
  auth(3),
  pair(4),
  versionMap(5),
  noteDelta(6),
  imageMeta(7),
  imageChunk(8),
  ack(9),
  error(10),
  bye(11);

  const SyncFrameType(this.code);

  final int code;

  static SyncFrameType fromCode(int code) =>
      values.firstWhere((t) => t.code == code, orElse: () => error);
}

/// 协议帧基类。
sealed class SyncFrame {
  const SyncFrame();

  SyncFrameType get type;

  Map<String, Object?> toJson();
}

/// Hello：设备 ID、应用/协议版本、身份公钥。
final class HelloFrame extends SyncFrame {
  const HelloFrame({
    required this.deviceId,
    required this.appVersion,
    required this.protocolVersion,
    required this.identityPublicKey,
  });

  final String deviceId;
  final String appVersion;
  final int protocolVersion;

  /// 身份公钥（base64，X25519 公钥）。
  final String identityPublicKey;

  @override
  SyncFrameType get type => SyncFrameType.hello;

  @override
  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'appVersion': appVersion,
        'protocolVersion': protocolVersion,
        'identityPublicKey': identityPublicKey,
      };
}

/// PeerInfo：握手后补充的对端信息（昵称、能力）。
final class PeerInfoFrame extends SyncFrame {
  const PeerInfoFrame({required this.deviceId, this.name, this.protocolVersion = 1});

  final String deviceId;
  final String? name;
  final int protocolVersion;

  @override
  SyncFrameType get type => SyncFrameType.peerInfo;

  @override
  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'name': name,
        'protocolVersion': protocolVersion,
      };
}

/// Auth：会话阶段交换临时 X25519 公钥与握手随机数。
final class AuthFrame extends SyncFrame {
  const AuthFrame({
    required this.deviceId,
    required this.sessionPublicKey,
    this.handshakeNonce,
  });

  final String deviceId;

  /// 临时会话公钥（base64）。
  final String sessionPublicKey;

  /// 随机数（base64），绑定会话，防止重放。
  final String? handshakeNonce;

  @override
  SyncFrameType get type => SyncFrameType.auth;

  @override
  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'sessionPublicKey': sessionPublicKey,
        'handshakeNonce': handshakeNonce,
      };
}

/// Pair：配对码验证（SAS）。首次配对时交换身份公钥并核对 6 位配对码。
final class PairFrame extends SyncFrame {
  const PairFrame({
    required this.deviceId,
    required this.code,
    required this.identityPublicKey,
    this.name,
  });

  final String deviceId;

  /// 6 位配对码（SAS 短认证串）。
  final String code;

  /// 身份公钥（base64）。
  final String identityPublicKey;

  final String? name;

  @override
  SyncFrameType get type => SyncFrameType.pair;

  @override
  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'code': code,
        'identityPublicKey': identityPublicKey,
        'name': name,
      };
}

/// 版本摘要中的单条记录。
class RecordVersion {
  const RecordVersion({
    required this.recordId,
    required this.updatedAt,
    required this.deviceId,
    required this.deleted,
  });

  final String recordId;
  final int updatedAt;
  final String deviceId;
  final bool deleted;

  Map<String, Object?> toJson() => {
        'recordId': recordId,
        'updatedAt': updatedAt,
        'deviceId': deviceId,
        'deleted': deleted,
      };

  factory RecordVersion.fromJson(Map<String, Object?> json) => RecordVersion(
        recordId: json['recordId']! as String,
        updatedAt: json['updatedAt']! as int,
        deviceId: json['deviceId']! as String,
        deleted: json['deleted']! as bool,
      );
}

/// VersionMap：记录版本摘要，用于增量比对。
final class VersionMapFrame extends SyncFrame {
  const VersionMapFrame({required this.entries});

  final List<RecordVersion> entries;

  @override
  SyncFrameType get type => SyncFrameType.versionMap;

  @override
  Map<String, Object?> toJson() => {
        'entries': [for (final e in entries) e.toJson()],
      };
}

/// 笔记载荷：Note 的完整协议表示（含字段版本）。
class NotePayload {
  const NotePayload({required this.note});

  final Note note;

  Map<String, Object?> toJson() => {
        'id': note.id,
        'title': note.title,
        'content': note.content,
        'timeBind': note.timeBind.name,
        'startAt': note.startAt?.millisecondsSinceEpoch,
        'endAt': note.endAt?.millisecondsSinceEpoch,
        'color': note.color,
        'location': note.location,
        'reminderOffsetMin': note.reminderOffsetMin,
        'reminderAt': note.reminderAt?.millisecondsSinceEpoch,
        'createdBy': note.createdBy,
        'createdAt': note.createdAt?.millisecondsSinceEpoch,
        'deleted': note.deleted,
        'deletedAt': note.deletedAt?.millisecondsSinceEpoch,
        'deletedBy': note.deletedBy,
        'fieldVersions': {
          for (final entry in note.fieldVersions.entries)
            entry.key: {'ts': entry.value.ts, 'device': entry.value.deviceId},
        },
      };

  factory NotePayload.fromJson(Map<String, Object?> json) {
    final versionsJson = json['fieldVersions'] as Map<String, Object?>? ?? const {};
    return NotePayload(
      note: Note(
        id: json['id']! as String,
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
        timeBind: TimeBind.values.firstWhere(
          (e) => e.name == json['timeBind'],
          orElse: () => TimeBind.none,
        ),
        startAt: _dateFrom(json['startAt']),
        endAt: _dateFrom(json['endAt']),
        color: json['color'] as String?,
        location: json['location'] as String?,
        reminderOffsetMin: json['reminderOffsetMin'] as int?,
        reminderAt: _dateFrom(json['reminderAt']),
        createdBy: json['createdBy'] as String?,
        createdAt: _dateFrom(json['createdAt']),
        deleted: json['deleted'] as bool? ?? false,
        deletedAt: _dateFrom(json['deletedAt']),
        deletedBy: json['deletedBy'] as String?,
        fieldVersions: {
          for (final entry in versionsJson.entries)
            entry.key: () {
              final v = entry.value! as Map<String, Object?>;
              return FieldVersion(v['ts']! as int, v['device']! as String);
            }(),
        },
      ),
    );
  }

  static DateTime? _dateFrom(Object? value) =>
      value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
}

/// NoteDelta：笔记创建/更新/删除（删除由 payload 内 deleted 标记表达）。
final class NoteDeltaFrame extends SyncFrame {
  const NoteDeltaFrame({required this.payload});

  final NotePayload payload;

  Note get note => payload.note;

  @override
  SyncFrameType get type => SyncFrameType.noteDelta;

  @override
  Map<String, Object?> toJson() => {'note': payload.toJson()};
}

/// 图片元数据载荷。
class ImagePayload {
  const ImagePayload({
    required this.id,
    required this.noteId,
    required this.fileName,
    required this.sha256,
    required this.size,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.lwTs = 0,
    this.lwDevice = '',
  });

  final String id;
  final String noteId;
  final String fileName;
  final String sha256;
  final int size;
  final bool deleted;
  final DateTime? deletedAt;
  final String? deletedBy;
  final int lwTs;
  final String lwDevice;

  Map<String, Object?> toJson() => {
        'id': id,
        'noteId': noteId,
        'fileName': fileName,
        'sha256': sha256,
        'size': size,
        'deleted': deleted,
        'deletedAt': deletedAt?.millisecondsSinceEpoch,
        'deletedBy': deletedBy,
        'lwTs': lwTs,
        'lwDevice': lwDevice,
      };

  factory ImagePayload.fromJson(Map<String, Object?> json) => ImagePayload(
        id: json['id']! as String,
        noteId: json['noteId']! as String,
        fileName: json['fileName']! as String,
        sha256: json['sha256']! as String,
        size: json['size']! as int,
        deleted: json['deleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] is int
            ? DateTime.fromMillisecondsSinceEpoch(json['deletedAt']! as int)
            : null,
        deletedBy: json['deletedBy'] as String?,
        lwTs: json['lwTs'] as int? ?? 0,
        lwDevice: json['lwDevice'] as String? ?? '',
      );
}

/// ImageMeta：图片元数据帧（不携带图片内容）。
final class ImageMetaFrame extends SyncFrame {
  const ImageMetaFrame({required this.payload});

  final ImagePayload payload;

  @override
  SyncFrameType get type => SyncFrameType.imageMeta;

  @override
  Map<String, Object?> toJson() => {'image': payload.toJson()};
}

/// ImageChunk：图片分块数据。
///
/// 载荷为二进制：`[4 字节大端 meta 长度][meta JSON][原始数据块]`。
final class ImageChunkFrame extends SyncFrame {
  const ImageChunkFrame({
    required this.imageId,
    required this.seq,
    required this.total,
    required this.size,
    required this.chunk,
  });

  final String imageId;

  /// 块序号（从 0 开始）。
  final int seq;

  /// 总块数。
  final int total;

  /// 整图大小（字节），用于续传校验。
  final int size;

  final Uint8List chunk;

  @override
  SyncFrameType get type => SyncFrameType.imageChunk;

  @override
  Map<String, Object?> toJson() => {
        'imageId': imageId,
        'seq': seq,
        'total': total,
        'size': size,
      };
}

/// Ack：确认（帧级/同步完成）。
final class AckFrame extends SyncFrame {
  const AckFrame({this.forType, this.ok = true, this.message});

  /// 确认针对的帧类型（可空，用于整体同步完成确认）。
  final SyncFrameType? forType;
  final bool ok;
  final String? message;

  @override
  SyncFrameType get type => SyncFrameType.ack;

  @override
  Map<String, Object?> toJson() => {
        'forType': forType?.code,
        'ok': ok,
        'message': message,
      };
}

/// Error：协议错误。
final class ErrorFrame extends SyncFrame {
  const ErrorFrame({required this.code, required this.message, this.fatal = false});

  final String code;
  final String message;
  final bool fatal;

  @override
  SyncFrameType get type => SyncFrameType.error;

  @override
  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'fatal': fatal,
      };
}

/// Bye：优雅关闭连接。
final class ByeFrame extends SyncFrame {
  const ByeFrame({this.reason});

  final String? reason;

  @override
  SyncFrameType get type => SyncFrameType.bye;

  @override
  Map<String, Object?> toJson() => {'reason': reason};
}

/// 从 JSON 还原帧。
SyncFrame frameFromJson(SyncFrameType type, Map<String, Object?> json) {
  switch (type) {
    case SyncFrameType.hello:
      return HelloFrame(
        deviceId: json['deviceId']! as String,
        appVersion: json['appVersion']! as String,
        protocolVersion: json['protocolVersion']! as int,
        identityPublicKey: json['identityPublicKey']! as String,
      );
    case SyncFrameType.peerInfo:
      return PeerInfoFrame(
        deviceId: json['deviceId']! as String,
        name: json['name'] as String?,
        protocolVersion: json['protocolVersion'] as int? ?? 1,
      );
    case SyncFrameType.auth:
      return AuthFrame(
        deviceId: json['deviceId']! as String,
        sessionPublicKey: json['sessionPublicKey']! as String,
        handshakeNonce: json['handshakeNonce'] as String?,
      );
    case SyncFrameType.pair:
      return PairFrame(
        deviceId: json['deviceId']! as String,
        code: json['code']! as String,
        identityPublicKey: json['identityPublicKey']! as String,
        name: json['name'] as String?,
      );
    case SyncFrameType.versionMap:
      final entries = (json['entries']! as List<Object?>)
          .cast<Map<String, Object?>>()
          .map(RecordVersion.fromJson)
          .toList();
      return VersionMapFrame(entries: entries);
    case SyncFrameType.noteDelta:
      return NoteDeltaFrame(
        payload: NotePayload.fromJson(json['note']! as Map<String, Object?>),
      );
    case SyncFrameType.imageMeta:
      return ImageMetaFrame(
        payload: ImagePayload.fromJson(json['image']! as Map<String, Object?>),
      );
    case SyncFrameType.imageChunk:
      throw StateError('imageChunk 使用二进制编解码，不走 JSON');
    case SyncFrameType.ack:
      return AckFrame(
        forType: json['forType'] == null ? null : SyncFrameType.fromCode(json['forType']! as int),
        ok: json['ok'] as bool? ?? true,
        message: json['message'] as String?,
      );
    case SyncFrameType.error:
      return ErrorFrame(
        code: json['code']! as String,
        message: json['message']! as String,
        fatal: json['fatal'] as bool? ?? false,
      );
    case SyncFrameType.bye:
      return ByeFrame(reason: json['reason'] as String?);
  }
}

/// 便捷函数：构造完整的协议 JSON（供帧编解码复用）。
Map<String, Object?> frameJson(SyncFrame frame) => frame.toJson();

/// JSON 编解码辅助（UTF-8）。
Uint8List jsonBytes(Object json) => Uint8List.fromList(utf8.encode(jsonEncode(json)));

Map<String, Object?> jsonFromBytes(Uint8List bytes) =>
    jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
