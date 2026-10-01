import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:couple_space/core/crypto/channel.dart';
import 'package:couple_space/core/crypto/keys.dart';
import 'package:couple_space/core/models/note.dart';
import 'package:couple_space/core/sync/protocol/frames.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/memory_connection.dart';

void main() {
  group('身份密钥与 ECDH', () {
    test('双方 X25519 算出相同共享密钥，第三方不同', () async {
      final aliceSession = await EcdhSession.generate();
      final bobSession = await EcdhSession.generate();
      final eveSession = await EcdhSession.generate();

      final aliceShared = await aliceSession.sharedSecretWith(bobSession.publicKey);
      final bobShared = await bobSession.sharedSecretWith(aliceSession.publicKey);
      final eveShared = await eveSession.sharedSecretWith(bobSession.publicKey);

      final aliceBytes = await aliceShared.extractBytes();
      final bobBytes = await bobShared.extractBytes();
      final eveBytes = await eveShared.extractBytes();
      expect(aliceBytes, bobBytes);
      expect(aliceBytes, isNot(eveBytes));
    });

    test('从种子可重建相同身份密钥', () async {
      final original = await IdentityKeys.generate('deviceA');
      final restored = await IdentityKeys.fromSeed('deviceA', original.seed);
      expect(restored.publicKey, original.publicKey);
      expect(restored.publicKeyBase64, base64Encode(original.publicKey));
    });
  });

  group('会话密钥与配对码', () {
    test('双方派生出相同会话密钥', () async {
      final alice = await EcdhSession.generate();
      final bob = await EcdhSession.generate();
      final shared = await alice.sharedSecretWith(bob.publicKey);

      final aliceKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: alice.publicKey,
        peerSessionPublicKey: bob.publicKey,
      );
      final bobKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: bob.publicKey,
        peerSessionPublicKey: alice.publicKey,
      );

      expect(await aliceKey.extractBytes(), await bobKey.extractBytes());
      expect((await aliceKey.extractBytes()).length, 32);
    });

    test('会话密钥绑定双方公钥（换对端则不同）', () async {
      final alice = await EcdhSession.generate();
      final bob = await EcdhSession.generate();
      final eve = await EcdhSession.generate();
      final shared = await alice.sharedSecretWith(bob.publicKey);

      final withBob = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: alice.publicKey,
        peerSessionPublicKey: bob.publicKey,
      );
      final withEve = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: alice.publicKey,
        peerSessionPublicKey: eve.publicKey,
      );
      expect(await withBob.extractBytes(), isNot(await withEve.extractBytes()));
    });

    test('配对码为 6 位且双方一致、依赖身份公钥', () async {
      final aliceIdentity = await IdentityKeys.generate('deviceA');
      final bobIdentity = await IdentityKeys.generate('deviceB');
      final eveIdentity = await IdentityKeys.generate('deviceE');
      final aliceSession = await EcdhSession.generate();
      final bobSession = await EcdhSession.generate();
      final shared = await aliceSession.sharedSecretWith(bobSession.publicKey);

      final aliceCode = await SessionKeys.pairingCode(
        sharedSecret: shared,
        ourIdentityPublicKey: aliceIdentity.publicKey,
        peerIdentityPublicKey: bobIdentity.publicKey,
      );
      final bobCode = await SessionKeys.pairingCode(
        sharedSecret: shared,
        ourIdentityPublicKey: bobIdentity.publicKey,
        peerIdentityPublicKey: aliceIdentity.publicKey,
      );
      expect(aliceCode, bobCode);
      expect(RegExp(r'^\d{6}$').hasMatch(aliceCode), isTrue);

      final eveCode = await SessionKeys.pairingCode(
        sharedSecret: shared,
        ourIdentityPublicKey: eveIdentity.publicKey,
        peerIdentityPublicKey: bobIdentity.publicKey,
      );
      expect(eveCode, isNot(aliceCode));
    });
  });

  group('EncryptedChannel', () {
    test('加密往返：明文一致、密文不含明文、每条 nonce 不同', () async {
      final duplex = MemoryDuplex.pair();
      final aliceSession = await EcdhSession.generate();
      final bobSession = await EcdhSession.generate();
      final shared = await aliceSession.sharedSecretWith(bobSession.publicKey);
      final aliceKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: aliceSession.publicKey,
        peerSessionPublicKey: bobSession.publicKey,
      );
      final bobKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: bobSession.publicKey,
        peerSessionPublicKey: aliceSession.publicKey,
      );

      final alice = EncryptedChannel(connection: duplex.a, sessionKey: aliceKey);
      final bob = EncryptedChannel(connection: duplex.b, sessionKey: bobKey);
      bob.start();

      final received = <List<int>>[];
      final sub = bob.incoming.listen(received.add);

      final message = utf8.encode('一起记录的小秘密');
      await alice.send(message);
      await alice.send(message);

      await _waitUntil(() => received.length >= 2);
      expect(received.length, 2);
      expect(received[0], message);
      expect(received[1], message);

      final sent1 = duplex.a.sentBytes;
      expect(utf8.decode(sent1, allowMalformed: true), isNot(contains('小秘密')));
      // 两条消息密文帧不同（随机 nonce）。
      final raw = duplex.a.sent.toBytes();
      final len1 = ByteData.sublistView(raw).getUint32(0);
      final frame1 = Uint8List.sublistView(raw, 0, 4 + len1);
      final frame2 = Uint8List.sublistView(raw, 4 + len1);
      expect(frame1, isNot(orderedEquals(frame2)));

      await sub.cancel();
    });

    test('密文被篡改时解密失败并报告认证错误', () async {
      final duplex = MemoryDuplex.pair();
      final aliceSession = await EcdhSession.generate();
      final bobSession = await EcdhSession.generate();
      final shared = await aliceSession.sharedSecretWith(bobSession.publicKey);
      final key = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: aliceSession.publicKey,
        peerSessionPublicKey: bobSession.publicKey,
      );

      final alice = EncryptedChannel(connection: duplex.a, sessionKey: key);
      final bob = EncryptedChannel(connection: duplex.b, sessionKey: key);
      bob.start();

      final errors = <Object>[];
      final sub = bob.incoming.listen((_) {}, onError: (Object e) {
        errors.add(e);
      });

      await alice.send(utf8.encode('hello'));
      // 翻转密文中的最后一个字节。
      final raw = duplex.a.sentBytes;
      raw[raw.length - 1] ^= 0x01;
      duplex.b.inject(raw);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(errors, isNotEmpty);
      expect(errors.first, isA<SecretBoxAuthenticationError>());
      await sub.cancel();
    });
  });

  group('EncryptedFrameChannel', () {
    test('加密协议帧端到端往返（含中文笔记）', () async {
      final duplex = MemoryDuplex.pair();
      final aliceSession = await EcdhSession.generate();
      final bobSession = await EcdhSession.generate();
      final shared = await aliceSession.sharedSecretWith(bobSession.publicKey);
      final aliceKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: aliceSession.publicKey,
        peerSessionPublicKey: bobSession.publicKey,
      );
      final bobKey = await SessionKeys.deriveSessionKey(
        sharedSecret: shared,
        ourSessionPublicKey: bobSession.publicKey,
        peerSessionPublicKey: aliceSession.publicKey,
      );

      final alice = EncryptedFrameChannel(connection: duplex.a, sessionKey: aliceKey);
      final bob = EncryptedFrameChannel(connection: duplex.b, sessionKey: bobKey);
      bob.start();

      final received = <SyncFrame>[];
      final sub = bob.frames.listen(received.add);

      await alice.sendFrame(
        const HelloFrame(
          deviceId: 'deviceA',
          appVersion: '0.1.0',
          protocolVersion: 1,
          identityPublicKey: 'cHVia2V5',
        ),
      );
      await alice.sendFrame(
        NoteDeltaFrame(
          payload: NotePayload(
            note: Note(
              id: 'n1',
              content: '加密后的正文',
              fieldVersions: {'content': const FieldVersion(100, 'deviceA')},
            ),
          ),
        ),
      );

      await _waitUntil(() => received.length >= 2);
      expect(received.length, 2);
      expect(received[0], isA<HelloFrame>());
      expect((received[1] as NoteDeltaFrame).note.content, '加密后的正文');
      await sub.cancel();
    });
  });
}

Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('等待条件超时', timeout);
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
