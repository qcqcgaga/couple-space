import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../crypto/channel.dart';
import '../crypto/keys.dart';
import '../models/image.dart';
import '../models/note.dart';
import '../models/note_edit.dart';
import '../storage/image_files.dart';
import 'chunk_bitmap.dart';
import 'protocol/codec.dart';
import 'protocol/frames.dart';
import 'sync_storage.dart';
import 'transports/transport.dart';

/// 同步事件类型。
enum SyncEventKind {
  connecting,
  handshaking,
  paired,
  syncing,
  noteSynced,
  imageMetaSynced,
  imageTransferProgress,
  imageTransferDone,
  imageTransferFailed,
  synced,
  error,
  closed,
}

/// 同步引擎对外事件。
class SyncEvent {
  const SyncEvent(this.kind, {this.peerDeviceId, this.message, this.imageId, this.progress, this.total});

  final SyncEventKind kind;
  final String? peerDeviceId;
  final String? message;
  final String? imageId;
  final int? progress;
  final int? total;
}

/// 配对挑战：握手需要用户确认 SAS（配对码）时发出。
class PairingChallenge {
  const PairingChallenge({
    required this.peerDeviceId,
    required this.code,
    this.verifiedByQr = false,
  });

  final String peerDeviceId;

  /// 本端由 ECDH 共享密钥计算出的 6 位配对码（UI 展示/用户比对用）。
  final String code;

  /// 是否已通过二维码锁定对端身份公钥（扫码后仍须比对并确认 SAS）。
  final bool verifiedByQr;
}

/// 同步引擎配置。
class SyncEngineOptions {
  const SyncEngineOptions({
    this.appVersion = '0.1.0',
    this.protocolVersion = 1,
    this.deviceName = '',
    this.chunkSize = 256 * 1024,
    this.handshakeTimeout = const Duration(seconds: 30),
    this.maxFramePayloadLength = SyncFrameCodec.maxPayloadLength,
    this.autoAcceptPairing = false,
    this.maxImageChunksPerSession,
  });

  final String appVersion;
  final int protocolVersion;
  final String deviceName;

  /// 图片分块大小（字节），发送/接收双方需一致。
  final int chunkSize;
  final Duration handshakeTimeout;
  final int maxFramePayloadLength;

  /// 自动接受本端计算出的配对码（仅测试/探针用；生产必须人工比对确认）。
  final bool autoAcceptPairing;

  /// 单次会话最多发送的图片块数（测试/限流用；null 表示不限）。
  final int? maxImageChunksPerSession;

  int get effectiveChunkSize => chunkSize <= 0 ? 256 * 1024 : chunkSize;
}

/// 握手/协议异常。
class SyncHandshakeException implements Exception {
  const SyncHandshakeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'SyncHandshakeException($code): $message';
}

/// 同步引擎：连接握手 → 身份校验/配对 → 会话密钥协商 → VersionMap 摘要比对
/// → 增量推送 NoteDelta / ImageMeta / ImageChunk → Ack（docs/02 §4）。
///
/// 传输层只提供可靠字节流（[Connection]），本引擎不关心底层是局域网还是
/// 蓝牙；图片与笔记独立同步——笔记落库即生效，图片字节按队列异步传输。
class SyncEngine {
  SyncEngine({
    required this.storage,
    required this.identity,
    required this.imageFiles,
    this.options = const SyncEngineOptions(),
  });

  final SyncStorage storage;
  final IdentityKeys identity;
  final ImageFileStore imageFiles;
  final SyncEngineOptions options;

  final StreamController<SyncEvent> _events = StreamController<SyncEvent>.broadcast();
  final StreamController<PairingChallenge> _challenges =
      StreamController<PairingChallenge>.broadcast();
  final Set<SyncSession> _sessions = <SyncSession>{};

  /// 全局串行化关键区（LWW 读改写 + 落库），避免并发会话写库竞态。
  Future<void> _dbTail = Future<void>.value();

  Completer<String>? _pairingCompleter;
  String? _expectedPairingCode;

  /// 二维码配对期望：扫码/粘贴二维码后预先锁定对端设备 ID 与身份公钥。
  ({String deviceId, String identityPublicKey})? _expectedPeer;

  Stream<SyncEvent> get events => _events.stream;

  Stream<PairingChallenge> get onPairingChallenge => _challenges.stream;

  /// 主动发起连接（对端为监听方）。
  Future<SyncSession> connect(Connection connection) =>
      _run(connection, isInitiator: true);

  /// 接受一条入站连接（由传输层 onIncoming 提供）。
  Future<SyncSession> accept(Connection connection) =>
      _run(connection, isInitiator: false);

  /// 用户确认配对码：唤醒等待中的配对握手；也可在连接前预先设置期望码。
  Future<void> confirmPairing(String code) async {
    _expectedPairingCode = code;
    final completer = _pairingCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(code);
    }
  }

  /// 通过二维码锁定对端身份：配对时校验对端 Hello 携带的身份公钥与
  /// 二维码内容一致（out-of-band 信任），随后仍需用户比对并确认 SAS。
  void prepareQrPairing(String peerDeviceId, String identityPublicKey) {
    _expectedPeer = (
      deviceId: peerDeviceId,
      identityPublicKey: identityPublicKey,
    );
  }

  /// 关闭全部会话（App 退出时调用）。
  Future<void> closeAll() async {
    final sessions = List<SyncSession>.of(_sessions);
    for (final session in sessions) {
      await session.close();
    }
  }

  Future<SyncSession> _run(Connection connection, {required bool isInitiator}) {
    final conn = SyncConnection(
      connection,
      maxPayloadLength: options.maxFramePayloadLength,
    );
    final session = SyncSession._(this, conn);
    _sessions.add(session);
    session._listen();
    conn.start();
    unawaited(_drive(session));
    return Future.value(session);
  }

  Future<void> _drive(SyncSession session) async {
    try {
      await _handshake(session);
      if (session._closed) return;
      await _sync(session);
    } on SyncHandshakeException catch (e) {
      await _fail(session, e.code, e.message);
    } catch (e) {
      _emit(SyncEvent(
        SyncEventKind.error,
        peerDeviceId: session.peerDeviceId,
        message: 'engine_error: $e',
      ));
      await session.close();
    }
  }

  // ---------- 握手 ----------

  Future<void> _handshake(SyncSession session) async {
    final conn = session.connection;
    _emit(SyncEvent(SyncEventKind.handshaking, peerDeviceId: session.peerDeviceId));

    // 1. 发送 Hello + PeerInfo；等待对端 Hello + PeerInfo。
    await conn.sendFrame(HelloFrame(
      deviceId: identity.deviceId,
      appVersion: options.appVersion,
      protocolVersion: options.protocolVersion,
      identityPublicKey: identity.publicKeyBase64,
    ));
    await conn.sendFrame(PeerInfoFrame(
      deviceId: identity.deviceId,
      name: options.deviceName,
      protocolVersion: options.protocolVersion,
    ));
    final peerHello = await session._hello.future.timeout(options.handshakeTimeout);
    final peerInfo = await session._peerInfo.future.timeout(options.handshakeTimeout);
    if (peerHello.protocolVersion != options.protocolVersion) {
      throw SyncHandshakeException(
        'protocol_mismatch',
        '协议版本不一致：本端 ${options.protocolVersion}，对端 ${peerHello.protocolVersion}',
      );
    }
    session.peerDeviceId = peerHello.deviceId;
    if (!session._peerKnown.isCompleted) {
      session._peerKnown.complete();
    }

    // 2. 会话密钥交换：交换临时 X25519 公钥。
    final ecdh = await EcdhSession.generate();
    final nonce = _randomBytes(16);
    final hasPeer = await storage.isPaired(peerHello.deviceId);
    await conn.sendFrame(AuthFrame(
      deviceId: identity.deviceId,
      sessionPublicKey: base64Encode(ecdh.publicKey),
      handshakeNonce: base64Encode(nonce),
      paired: hasPeer,
    ));
    final peerAuth = await session._auth.future.timeout(options.handshakeTimeout);
    if (peerAuth.deviceId != peerHello.deviceId) {
      throw const SyncHandshakeException('identity_mismatch', 'Auth 设备 ID 与 Hello 不一致');
    }

    // 3. 计算共享密钥与本端 SAS（配对码）。
    final shared = await ecdh.sharedSecretWith(base64Decode(peerAuth.sessionPublicKey));
    final peerIdentityKey = base64Decode(peerHello.identityPublicKey);
    final mySas = await SessionKeys.pairingCode(
      sharedSecret: shared,
      ourIdentityPublicKey: identity.publicKey,
      peerIdentityPublicKey: peerIdentityKey,
    );

    // 4. 未配对（任一方缺失）→ 配对流程；已配对 → 校验身份公钥。
    final needPairing = !hasPeer || !peerAuth.paired;
    if (needPairing) {
      await _pair(session, peerHello, peerInfo, mySas);
    } else {
      final row = await storage.findPeer(peerHello.deviceId);
      if (row == null || row.identityPublicKey != peerHello.identityPublicKey) {
        throw const SyncHandshakeException('identity_mismatch', '身份公钥与白名单不一致');
      }
      await conn.sendFrame(const AckFrame(forType: SyncFrameType.auth, ok: true));
    }

    // 等待对端最终确认（配对分支对端也会回 Ack(pair)）。
    final finalAck = await session._ack.future.timeout(options.handshakeTimeout);
    if (finalAck.forType != (needPairing ? SyncFrameType.pair : SyncFrameType.auth) ||
        !finalAck.ok) {
      throw SyncHandshakeException('handshake_failed', '对端握手确认失败: ${finalAck.message ?? ''}');
    }

    // 5. 派生会话密钥并升级加密通道；随后进入增量同步。
    final sessionKey = await SessionKeys.deriveSessionKey(
      sharedSecret: shared,
      ourSessionPublicKey: ecdh.publicKey,
      peerSessionPublicKey: base64Decode(peerAuth.sessionPublicKey),
    );
    session._phase = _SessionPhase.sync;
    // 先切阶段再升级：upgrade() 会冲刷握手期间缓冲的密文，
    // 其中可能已包含对端加密的 VersionMap，必须按同步阶段派发。
    await conn.upgrade(sessionKey);
    await storage.touchPeer(session.peerDeviceId!);
    _emit(SyncEvent(SyncEventKind.paired, peerDeviceId: session.peerDeviceId));
  }

  Future<void> _pair(
    SyncSession session,
    HelloFrame peerHello,
    PeerInfoFrame peerInfo,
    String mySas,
  ) async {
    final conn = session.connection;
    final expected = _expectedPeer;
    if (expected != null &&
        (expected.deviceId != peerHello.deviceId ||
            expected.identityPublicKey != peerHello.identityPublicKey)) {
      throw const SyncHandshakeException(
        'identity_mismatch',
        '对端身份与二维码信息不一致',
      );
    }

    if (!options.autoAcceptPairing) {
      if (_expectedPairingCode == null) {
        // 需要用户确认：发出挑战并等待 confirmPairing。
        final completer = Completer<String>();
        _pairingCompleter = completer;
        _challenges.add(PairingChallenge(
          peerDeviceId: peerHello.deviceId,
          code: mySas,
          verifiedByQr: expected != null,
        ));
        try {
          final entered = await completer.future.timeout(options.handshakeTimeout);
          if (entered != mySas) {
            throw const SyncHandshakeException('sas_mismatch', '输入的配对码与本端计算的 SAS 不一致');
          }
          _expectedPairingCode = entered;
        } finally {
          if (identical(_pairingCompleter, completer)) {
            _pairingCompleter = null;
          }
        }
      } else if (_expectedPairingCode != mySas) {
        throw const SyncHandshakeException('sas_mismatch', '预设配对码与本端计算的 SAS 不一致');
      }
    }

    await conn.sendFrame(PairFrame(
      deviceId: identity.deviceId,
      code: mySas,
      identityPublicKey: identity.publicKeyBase64,
      name: options.deviceName,
    ));

    // 校验对端 SAS 与身份公钥一致后写入白名单。
    final pair = await session._pair.future.timeout(options.handshakeTimeout);
    if (pair.code != mySas) {
      throw const SyncHandshakeException('sas_mismatch', '对端配对码与本端计算不一致');
    }
    if (pair.identityPublicKey != peerHello.identityPublicKey) {
      throw const SyncHandshakeException('identity_mismatch', 'Pair 身份公钥与 Hello 不一致');
    }
    await _serialized(() => storage.upsertPeer(
          deviceId: peerHello.deviceId,
          name: peerInfo.name,
          identityPublicKey: peerHello.identityPublicKey,
        ));
    // 配对成功后清除二维码期望，避免陈旧期望影响后续码配对。
    _expectedPeer = null;
    await conn.sendFrame(const AckFrame(forType: SyncFrameType.pair, ok: true));
  }

  // ---------- 增量同步 ----------

  Future<void> _sync(SyncSession session) async {
    final conn = session.connection;
    _emit(SyncEvent(SyncEventKind.syncing, peerDeviceId: session.peerDeviceId));
    final entries = await _versionEntries();
    await conn.sendFrame(VersionMapFrame(entries: entries));
    session._ownMapSent = true;
    await _maybeSendSyncDone(session);
  }

  Future<List<RecordVersion>> _versionEntries() async {
    final notes = await storage.allNotes(includeDeleted: true);
    final images = await storage.allImages(includeDeleted: true);
    final entries = <RecordVersion>[
      for (final note in notes)
        () {
          final summary = NoteVersions.summaryOf(note);
          return RecordVersion(
            recordId: note.id,
            updatedAt: summary.ts,
            deviceId: summary.deviceId,
            deleted: summary.deleted,
            kind: 'note',
          );
        }(),
      for (final image in images)
        RecordVersion(
          recordId: image.id,
          updatedAt: image.lwTs,
          deviceId: image.lwDevice,
          deleted: image.deleted,
          kind: 'image',
        ),
    ];
    return entries;
  }

  Future<void> _onVersionMap(SyncSession session, VersionMapFrame frame) async {
    await _pushDiffs(session, frame);
    session._peerMapProcessed = true;
    await _maybeSendSyncDone(session);
  }

  /// 摘要不同即双向推送完整记录：
  /// 字段级 LWW 要求携带全字段版本，仅“按较新摘要单向拉取”会漏掉
  /// 较旧摘要记录里的新字段写入（docs/04 ADR-018）。
  Future<void> _pushDiffs(SyncSession session, VersionMapFrame peerMap) async {
    final conn = session.connection;
    final peerNotes = <String, RecordVersion>{};
    final peerImages = <String, RecordVersion>{};
    for (final entry in peerMap.entries) {
      if (entry.kind == 'image') {
        peerImages[entry.recordId] = entry;
      } else {
        peerNotes[entry.recordId] = entry;
      }
    }

    final notes = await storage.allNotes(includeDeleted: true);
    for (final note in notes) {
      final peer = peerNotes[note.id];
      final summary = NoteVersions.summaryOf(note);
      if (peer == null ||
          peer.updatedAt != summary.ts ||
          peer.deviceId != summary.deviceId ||
          peer.deleted != summary.deleted) {
        await conn.sendFrame(NoteDeltaFrame(payload: NotePayload(note: note)));
      }
    }

    final images = await storage.allImages(includeDeleted: true);
    for (final image in images) {
      final peer = peerImages[image.id];
      final summaryDiffers = peer == null ||
          peer.updatedAt != image.lwTs ||
          peer.deviceId != image.lwDevice ||
          peer.deleted != image.deleted;
      final incomplete = !(await _isLocalFileComplete(image));
      // 本地图片不完整时也要推送 meta（携带我方位图），触发对端补发（续传）。
      if (summaryDiffers || incomplete) {
        await conn.sendFrame(ImageMetaFrame(payload: ImagePayload.fromMeta(image)));
      }
    }
  }

  Future<void> _onNoteDelta(SyncSession session, NoteDeltaFrame frame) async {
    final merged = await _serialized(() => storage.applyRemoteNote(frame.note));
    _emit(SyncEvent(
      SyncEventKind.noteSynced,
      peerDeviceId: session.peerDeviceId,
      message: merged.id,
    ));
  }

  Future<void> _onImageMeta(SyncSession session, ImageMetaFrame frame) async {
    final conn = session.connection;
    final payload = frame.payload;
    final remote = ImageMeta(
      id: payload.id,
      noteId: payload.noteId,
      fileName: payload.fileName,
      sha256: payload.sha256,
      size: payload.size,
      deleted: payload.deleted,
      deletedAt: payload.deletedAt,
      deletedBy: payload.deletedBy,
      lwTs: payload.lwTs,
      lwDevice: payload.lwDevice,
      syncStatus: payload.syncStatus,
      totalChunks: payload.totalChunks,
      chunkSize: payload.chunkSize,
      chunkBitmap: payload.chunkBitmap,
    );
    final merged = await _serialized(() async {
      final local = await storage.imageById(remote.id);
      final result = _mergeImage(local, remote);
      await storage.upsertImage(result);
      return result;
    });

    if (merged.deleted) {
      await _serialized(() async {
        await imageFiles.delete(merged);
        await storage.removeTransfersForImage(merged.id);
      });
      _emit(SyncEvent(
        SyncEventKind.imageMetaSynced,
        peerDeviceId: session.peerDeviceId,
        imageId: merged.id,
        message: 'deleted',
      ));
      return;
    }

    _emit(SyncEvent(
      SyncEventKind.imageMetaSynced,
      peerDeviceId: session.peerDeviceId,
      imageId: merged.id,
    ));

    final myComplete = await _isLocalFileComplete(merged);
    if (!myComplete) {
      // 我方缺块：回复带本地位图的 Ack，让对端从缺失块继续。
      final total = _totalChunks(merged);
      final status = merged.syncStatus == 'failed'
          ? 'failed_hash'
          : (merged.totalChunks > 0 ? 'partial' : 'missing');
      await conn.sendFrame(AckFrame(
        forType: SyncFrameType.imageMeta,
        ok: true,
        message: jsonEncode({
          'imageId': merged.id,
          'status': status,
          'bitmap': merged.chunkBitmap ?? ChunkBitmap.allZeroText(total),
          'totalChunks': total,
          'chunkSize': merged.chunkSize == 0 ? options.effectiveChunkSize : merged.chunkSize,
          'size': merged.size,
        }),
      ));
    }

    // 对端 meta 显示未收齐且我方文件完整 → 由我方补发缺失块。
    if (myComplete && !_payloadFileComplete(payload)) {
      await _startSending(
        session,
        merged,
        peerBitmap: payload.chunkBitmap,
        peerTotal: payload.totalChunks,
      );
    }
  }

  Future<void> _onImageChunk(SyncSession session, ImageChunkFrame frame) async {
    final image = await storage.imageById(frame.imageId);
    if (image == null || image.deleted) return;
    if (frame.size != image.size) {
      _emit(SyncEvent(
        SyncEventKind.imageTransferFailed,
        peerDeviceId: session.peerDeviceId,
        imageId: frame.imageId,
        message: '分块 size 与本地元数据不一致',
      ));
      return;
    }
    if (frame.seq < 0 || frame.seq >= frame.total) return;
    final chunkSize = image.chunkSize == 0 ? options.effectiveChunkSize : image.chunkSize;
    final offset = frame.seq * chunkSize;
    await _serialized(() async {
      await imageFiles.writeChunk(image, offset, frame.chunk);
      await storage.markChunkReceived(
        image.id,
        seq: frame.seq,
        chunkSize: chunkSize,
        totalChunks: frame.total,
      );
    });

    // 收齐后校验 sha256，防止传输损坏。
    final updated = await storage.imageById(frame.imageId);
    if (updated != null && updated.syncStatus == 'done') {
      final hash = await imageFiles.sha256(updated);
      if (hash == updated.sha256) {
        _emit(SyncEvent(
          SyncEventKind.imageTransferDone,
          peerDeviceId: session.peerDeviceId,
          imageId: updated.id,
          message: 'received',
        ));
      } else {
        await _serialized(() => storage.markImageFailed(updated.id, error: 'hash_mismatch'));
        _emit(SyncEvent(
          SyncEventKind.imageTransferFailed,
          peerDeviceId: session.peerDeviceId,
          imageId: updated.id,
          message: 'hash_mismatch',
        ));
      }
    }
  }

  Future<void> _onAck(SyncSession session, AckFrame frame) async {
    if (frame.forType == SyncFrameType.imageMeta && frame.ok && frame.message != null) {
      final msg = jsonDecode(frame.message!) as Map<String, Object?>;
      final imageId = msg['imageId'] as String?;
      if (imageId == null) return;
      final image = await storage.imageById(imageId);
      if (image == null || image.deleted) return;
      if (!await _isLocalFileComplete(image)) return;
      final status = msg['status'] as String?;
      final peerTotal = msg['totalChunks'] as int? ?? 0;
      final peerBitmap = msg['bitmap'] as String?;
      if (status == 'failed_hash') {
        await _startSending(session, image, force: true);
      } else if (peerTotal == 0 || !ChunkBitmap.textIsComplete(peerBitmap, peerTotal)) {
        await _startSending(session, image, peerBitmap: peerBitmap, peerTotal: peerTotal);
      }
    } else if (frame.forType == SyncFrameType.versionMap &&
        frame.ok &&
        frame.message == 'sync_done') {
      session._peerSyncDone = true;
      _maybeCompleteSync(session);
    }
  }

  Future<void> _startSending(
    SyncSession session,
    ImageMeta image, {
    String? peerBitmap,
    int? peerTotal,
    bool force = false,
  }) async {
    final peerId = session.peerDeviceId;
    if (peerId == null || session._activeTransfers.contains(image.id)) return;
    if (!await _isLocalFileComplete(image)) return;
    session._activeTransfers.add(image.id);
    final conn = session.connection;
    try {
      final total = _totalChunks(image);
      final chunkSize = image.chunkSize == 0 ? options.effectiveChunkSize : image.chunkSize;
      if (total == 0) {
        await storage.enqueueTransfer(peerId, image.id, chunkSize: chunkSize, totalChunks: 0);
        await storage.updateTransfer(peerId, image.id, status: 'done');
        _emit(SyncEvent(
          SyncEventKind.imageTransferDone,
          peerDeviceId: peerId,
          imageId: image.id,
        ));
        return;
      }
      await storage.enqueueTransfer(peerId, image.id, chunkSize: chunkSize, totalChunks: total);
      // 续传以接收方位图为准；总数不一致或强制重传时全量发送。
      final bitmap = (peerBitmap != null && peerTotal == total) ? peerBitmap : null;
      final missing = force
          ? List<int>.generate(total, (i) => i)
          : ChunkBitmap.missingSequences(bitmap, total);
      final sent = List<bool>.filled(total, false);
      var sentBytes = 0;
      var sentCount = 0;
      for (final seq in missing) {
        if (options.maxImageChunksPerSession != null &&
            sentCount >= options.maxImageChunksPerSession!) {
          break;
        }
        final offset = seq * chunkSize;
        final length = min(chunkSize, image.size - offset);
        final bytes = await imageFiles.readChunk(image, offset, length);
        await conn.sendFrame(ImageChunkFrame(
          imageId: image.id,
          seq: seq,
          total: total,
          size: image.size,
          chunk: bytes,
        ));
        sent[seq] = true;
        sentBytes += bytes.length;
        sentCount++;
        if (sentCount % 10 == 0) {
          await storage.updateTransfer(
            peerId,
            image.id,
            status: 'transferring',
            sentBitmap: ChunkBitmap.toText(sent),
            sentBytes: sentBytes,
          );
          _emit(SyncEvent(
            SyncEventKind.imageTransferProgress,
            peerDeviceId: peerId,
            imageId: image.id,
            progress: sentCount,
            total: total,
          ));
        }
      }
      await storage.updateTransfer(
        peerId,
        image.id,
        status: 'transferring',
        sentBitmap: ChunkBitmap.toText(sent),
        sentBytes: sentBytes,
      );
      _emit(SyncEvent(
        SyncEventKind.imageTransferProgress,
        peerDeviceId: peerId,
        imageId: image.id,
        progress: sentCount,
        total: total,
      ));
      if (sentCount >= missing.length) {
        await storage.updateTransfer(
          peerId,
          image.id,
          status: 'done',
          sentBitmap: ChunkBitmap.toText(sent),
          sentBytes: sentBytes,
        );
        _emit(SyncEvent(
          SyncEventKind.imageTransferDone,
          peerDeviceId: peerId,
          imageId: image.id,
        ));
      }
    } catch (e) {
      await storage.updateTransfer(peerId, image.id, status: 'failed', error: e.toString());
      _emit(SyncEvent(
        SyncEventKind.imageTransferFailed,
        peerDeviceId: peerId,
        imageId: image.id,
        message: e.toString(),
      ));
    } finally {
      session._activeTransfers.remove(image.id);
    }
  }

  // ---------- 会话收尾 ----------

  Future<void> _maybeSendSyncDone(SyncSession session) async {
    if (session._ownMapSent && session._peerMapProcessed && !session._syncDoneSent) {
      session._syncDoneSent = true;
      try {
        await session.connection.sendFrame(const AckFrame(
          forType: SyncFrameType.versionMap,
          ok: true,
          message: 'sync_done',
        ));
      } catch (e) {
        _emit(SyncEvent(
          SyncEventKind.error,
          peerDeviceId: session.peerDeviceId,
          message: '发送 sync_done 失败: $e',
        ));
        unawaited(_closeSession(session));
      }
    }
  }

  void _maybeCompleteSync(SyncSession session) {
    if (session._syncDoneSent && session._peerSyncDone && !session._syncCompleted) {
      session._syncCompleted = true;
      unawaited(_finishSync(session).catchError((Object e) {
        _emit(SyncEvent(
          SyncEventKind.error,
          peerDeviceId: session.peerDeviceId,
          message: '同步收尾失败: $e',
        ));
      }));
    }
  }

  Future<void> _finishSync(SyncSession session) async {
    // 记录最后同步向量（本轮收敛的最大更新时间），供下次增量参考。
    final notes = await storage.allNotes(includeDeleted: true);
    final images = await storage.allImages(includeDeleted: true);
    var maxTs = 0;
    for (final note in notes) {
      maxTs = max(maxTs, NoteVersions.lastUpdatedAt(note));
    }
    for (final image in images) {
      maxTs = max(maxTs, image.lwTs);
    }
    await storage.setSyncStateInt('lastSyncVector_${session.peerDeviceId}', maxTs);
    await storage.touchPeer(session.peerDeviceId!);
    if (!session._synced.isCompleted) {
      session._synced.complete();
    }
    _emit(SyncEvent(
      SyncEventKind.synced,
      peerDeviceId: session.peerDeviceId,
      message: 'lastSyncVector=$maxTs',
    ));
  }

  Future<void> _fail(SyncSession session, String code, String message) async {
    if (session._closed) return;
    _emit(SyncEvent(
      SyncEventKind.error,
      peerDeviceId: session.peerDeviceId,
      message: '$code: $message',
    ));
    try {
      await session.connection.sendFrame(ErrorFrame(code: code, message: message, fatal: true));
    } catch (_) {}
    await session.close();
  }

  Future<void> _closeSession(SyncSession session) async {
    if (session._closed) return;
    session._closed = true;
    _sessions.remove(session);
    try {
      await session.connection.sendFrame(const ByeFrame(reason: 'bye'));
    } catch (_) {
      // 连接可能已断开，忽略。
    }
    try {
      await session.connection.close();
    } catch (_) {
      // 关闭失败不阻塞会话收尾。
    }
    await session._sub?.cancel();
    if (!session._done.isCompleted) {
      session._done.complete();
    }
    _emit(SyncEvent(SyncEventKind.closed, peerDeviceId: session.peerDeviceId));
  }

  void _onSyncError(SyncSession session, Object error, StackTrace stackTrace) {
    if (session._closed) return;
    _emit(SyncEvent(
      SyncEventKind.error,
      peerDeviceId: session.peerDeviceId,
      message: error.toString(),
    ));
    unawaited(_closeSession(session));
  }

  /// 握手阶段帧分发（同步执行，保证 finishHandshake 的字节边界正确）。
  void _onHandshakeFrame(SyncSession session, SyncFrame frame) {
    switch (frame) {
      case HelloFrame():
        if (!session._hello.isCompleted) {
          session._hello.complete(frame);
        }
      case PeerInfoFrame():
        if (!session._peerInfo.isCompleted) {
          session._peerInfo.complete(frame);
        }
      case AuthFrame():
        if (!session._auth.isCompleted) {
          session._auth.complete(frame);
        }
      case PairFrame():
        if (!session._pair.isCompleted) {
          session._pair.complete(frame);
        }
      case AckFrame():
        if (!session._ack.isCompleted) {
          session._ack.complete(frame);
          if (frame.forType == SyncFrameType.auth ||
              frame.forType == SyncFrameType.pair) {
            // 对端已结束明文阶段：本端同步标记，同块字节的剩余部分按密文处理。
            session.connection.finishHandshake();
          }
        }
      case ErrorFrame():
        _emit(SyncEvent(
          SyncEventKind.error,
          peerDeviceId: session.peerDeviceId,
          message: '${frame.code}: ${frame.message}',
        ));
        unawaited(_closeSession(session));
      case ByeFrame():
        unawaited(_closeSession(session));
      default:
        break;
    }
  }

  /// 同步阶段帧分发（经会话队列串行执行）。
  Future<void> _onSyncFrame(SyncSession session, SyncFrame frame) async {
    switch (frame) {
      case VersionMapFrame():
        await _onVersionMap(session, frame);
      case NoteDeltaFrame():
        await _onNoteDelta(session, frame);
      case ImageMetaFrame():
        await _onImageMeta(session, frame);
      case ImageChunkFrame():
        await _onImageChunk(session, frame);
      case AckFrame():
        await _onAck(session, frame);
      case ErrorFrame():
        _emit(SyncEvent(
          SyncEventKind.error,
          peerDeviceId: session.peerDeviceId,
          message: '${frame.code}: ${frame.message}',
        ));
        await session.close();
      case ByeFrame():
        await session.close();
      default:
        break;
    }
  }

  /// 引擎级串行化：保证 LWW 读改写与落库按顺序执行。
  Future<T> _serialized<T>(Future<T> Function() task) {
    final result = _dbTail.then((_) => task());
    _dbTail = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  void _emit(SyncEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  /// 生成随机字节（dart:math Random 没有 nextBytes，手动填充）。
  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  // ---------- 内部辅助 ----------

  Future<bool> _isLocalFileComplete(ImageMeta image) async {
    if (image.deleted) return true;
    if (!await imageFiles.exists(image)) return false;
    final size = await imageFiles.size(image);
    if (size != image.size) return false;
    if (image.size == 0) return true;
    if (image.syncStatus == 'done') return true;
    return ChunkBitmap.textIsComplete(image.chunkBitmap, image.totalChunks);
  }

  bool _payloadFileComplete(ImagePayload payload) {
    if (payload.deleted || payload.size == 0) return true;
    if (payload.syncStatus == 'done') return true;
    return payload.totalChunks > 0 &&
        payload.chunkBitmap != null &&
        ChunkBitmap.textIsComplete(payload.chunkBitmap, payload.totalChunks);
  }

  int _totalChunks(ImageMeta image) {
    if (image.size == 0) return 0;
    final chunkSize = image.chunkSize == 0 ? options.effectiveChunkSize : image.chunkSize;
    return (image.size + chunkSize - 1) ~/ chunkSize;
  }

  /// 图片级 LWW 合并：比较 (lwTs, lwDevice)；同一文件内容时保留本地续传进度。
  ImageMeta _mergeImage(ImageMeta? local, ImageMeta remote) {
    final localVersion = FieldVersion(local?.lwTs ?? 0, local?.lwDevice ?? '');
    final remoteVersion = FieldVersion(remote.lwTs, remote.lwDevice);
    if (remoteVersion.compareTo(localVersion) <= 0) {
      return local!;
    }
    if (local != null && local.sha256 == remote.sha256 && local.size == remote.size) {
      if (local.chunkSize != 0 &&
          remote.chunkSize != 0 &&
          local.chunkSize != remote.chunkSize) {
        // 分块配置变化会使旧位图失效，重置后按对端配置重传。
        return ImageMeta(
          id: remote.id,
          noteId: remote.noteId,
          fileName: remote.fileName,
          sha256: remote.sha256,
          size: remote.size,
          deleted: remote.deleted,
          deletedAt: remote.deletedAt,
          deletedBy: remote.deletedBy,
          syncStatus: 'pending',
          chunkBitmap: null,
          totalChunks: 0,
          chunkSize: remote.chunkSize,
          lwTs: remote.lwTs,
          lwDevice: remote.lwDevice,
        );
      }
      return remote.copyWith(
        chunkBitmap: local.chunkBitmap,
        totalChunks: local.totalChunks,
        chunkSize: local.chunkSize == 0 ? remote.chunkSize : local.chunkSize,
        syncStatus: local.syncStatus,
      );
    }
    // 远端较新且内容不同（新图/替换）：本机尚未收到任何块。
    // 注意：remote.chunkBitmap 是发送方的“已收”状态，不能作为本机接收进度。
    return ImageMeta(
      id: remote.id,
      noteId: remote.noteId,
      fileName: remote.fileName,
      sha256: remote.sha256,
      size: remote.size,
      deleted: remote.deleted,
      deletedAt: remote.deletedAt,
      deletedBy: remote.deletedBy,
      syncStatus: 'pending',
      chunkBitmap: null,
      totalChunks: remote.totalChunks,
      chunkSize: remote.chunkSize,
      lwTs: remote.lwTs,
      lwDevice: remote.lwDevice,
    );
  }
}

/// 同步会话：一次连接的生命周期（握手 + 增量同步 + 图片传输）。
class SyncSession {
  SyncSession._(this._engine, this.connection);

  final SyncEngine _engine;
  final SyncConnection connection;

  final Completer<HelloFrame> _hello = Completer<HelloFrame>();
  final Completer<PeerInfoFrame> _peerInfo = Completer<PeerInfoFrame>();
  final Completer<AuthFrame> _auth = Completer<AuthFrame>();
  final Completer<PairFrame> _pair = Completer<PairFrame>();
  final Completer<AckFrame> _ack = Completer<AckFrame>();
  final Completer<void> _done = Completer<void>();
  final Completer<void> _synced = Completer<void>();
  final Completer<void> _peerKnown = Completer<void>();
  final Set<String> _activeTransfers = <String>{};

  _SessionPhase _phase = _SessionPhase.handshake;
  StreamSubscription<SyncFrame>? _sub;
  Future<void> _tail = Future<void>.value();
  String? peerDeviceId;
  bool _ownMapSent = false;
  bool _peerMapProcessed = false;
  bool _syncDoneSent = false;
  bool _peerSyncDone = false;
  bool _syncCompleted = false;
  bool _closed = false;

  /// 连接结束（关闭/断开）后完成。
  Future<void> get done => _done.future;

  /// 本轮增量同步收敛（笔记/元数据）后完成；图片字节可能仍在后台传输。
  Future<void> get synced => _synced.future;

  /// 握手识别出对端设备 ID 后完成（供上层按 peer 去重会话）。
  Future<void> get peerKnown => _peerKnown.future;

  Future<void> close() => _engine._closeSession(this);

  void _listen() {
    _sub = connection.frames.listen(
      (frame) {
        if (_phase == _SessionPhase.handshake) {
          _engine._onHandshakeFrame(this, frame);
        } else {
          enqueue(() => _engine._onSyncFrame(this, frame));
        }
      },
      onError: (Object e, StackTrace s) => _engine._onSyncError(this, e, s),
      onDone: () {
        _engine._closeSession(this);
      },
    );
  }

  /// 串行化同步阶段帧处理，避免并发写库。
  void enqueue(Future<void> Function() task) {
    final result = _tail.then((_) async {
      try {
        await task();
      } catch (e, s) {
        _engine._onSyncError(this, e, s);
      }
    });
    _tail = result;
  }
}

enum _SessionPhase { handshake, sync }

/// 引擎侧连接：同一底层字节流先解明文握手帧，会话密钥协商完成后无缝升级为
/// 加密帧通道。dart:io Socket 是单订阅流，不能“明文、密文各监听一次”，
/// 因此由本类统一消费字节并按阶段路由。
class SyncConnection {
  SyncConnection(this.connection, {this.maxPayloadLength = SyncFrameCodec.maxPayloadLength});

  final Connection connection;
  final int maxPayloadLength;

  late final FrameDecoder _plain = FrameDecoder(maxPayloadLength: maxPayloadLength);
  late final FrameDecoder _secure = FrameDecoder(maxPayloadLength: maxPayloadLength);
  final StreamController<SyncFrame> _frames =
      StreamController<SyncFrame>.broadcast();
  final BytesBuilder _cipherPending = BytesBuilder(copy: false);
  EncryptedChannel? _channel;
  bool _started = false;
  bool _handshakeDone = false;
  bool _upgraded = false;
  Future<void> _sendTail = Future<void>.value();

  Stream<SyncFrame> get frames => _frames.stream;

  void start() {
    if (_started) return;
    _started = true;
    connection.incoming.listen(
      _onData,
      onError: (Object e, StackTrace s) {
        if (!_frames.isClosed) {
          _frames.addError(e, s);
        }
      },
      onDone: () {
        _frames.close();
      },
    );
  }

  Future<void> _onData(List<int> chunk) async {
    try {
      if (_upgraded) {
        await _channel!.feed(chunk);
        return;
      }
      if (_handshakeDone) {
        _cipherPending.add(chunk);
        return;
      }
      final frames = _plain.add(chunk);
      for (final frame in frames) {
        // 监听器在处理最后一帧握手帧时会同步调用 finishHandshake()。
        _frames.add(frame);
      }
      if (_handshakeDone) {
        // 同一块字节里握手帧之后的剩余部分属于密文。
        final rest = _plain.takeRemaining();
        if (rest.isNotEmpty) {
          _cipherPending.add(rest);
        }
      }
    } catch (e, s) {
      _frames.addError(e, s);
    }
  }

  /// 引擎在处理握手最后一帧（对端最终 Ack）时同步调用，标记明文阶段结束。
  void finishHandshake() {
    _handshakeDone = true;
  }

  /// 建立加密通道并冲刷握手期间缓冲的密文字节。
  Future<void> upgrade(SecretKey sessionKey) async {
    if (_upgraded) return;
    _upgraded = true;
    _channel = EncryptedChannel(connection: connection, sessionKey: sessionKey);
    _channel!.incoming.listen(
      (bytes) {
        for (final frame in _secure.add(bytes)) {
          // 会话可能已先一步关闭（如对端回包竞态），丢弃迟到帧。
          if (!_frames.isClosed) {
            _frames.add(frame);
          }
        }
      },
      onError: (Object e, StackTrace s) {
        if (!_frames.isClosed) {
          _frames.addError(e, s);
        }
      },
      onDone: () {
        _frames.close();
      },
    );
    final pending = _cipherPending.takeBytes();
    if (pending.isNotEmpty) {
      await _channel!.feed(Uint8List.fromList(pending));
    }
  }

  Future<void> sendFrame(SyncFrame frame) {
    // 串行化发送：驱动协程与帧处理器可能并发发送（如 VersionMap 与
    // NoteDelta），Windows 下 Socket.flush() 并发会报
    // “StreamSink is bound to a stream”。
    final result = _sendTail.then((_) async {
      if (_upgraded) {
        await _channel!.send(SyncFrameCodec.encode(frame));
      } else if (_handshakeDone) {
        throw StateError('加密通道尚未建立，不能发送密文帧');
      } else {
        await connection.send(SyncFrameCodec.encode(frame));
      }
    });
    _sendTail = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<void> close() async {
    if (_upgraded) {
      await _channel!.close();
    } else {
      await connection.close();
    }
  }
}
