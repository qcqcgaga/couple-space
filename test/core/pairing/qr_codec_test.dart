import 'package:couple_space/core/pairing/qr_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PairQrCodec', () {
    test('编码解码往返一致（含公钥特殊字符 + / =）', () {
      const data = PairQrData(
        deviceId: 'dev-12345678',
        name: '小明的手机',
        identityPublicKey: 'A/+B/==abcdXYZ0123=',
      );
      final decoded = PairQrCodec.decode(PairQrCodec.encode(data));
      expect(decoded.deviceId, data.deviceId);
      expect(decoded.name, data.name);
      expect(decoded.identityPublicKey, data.identityPublicKey);
    });

    test('无昵称时省略 name 参数，解码回空串', () {
      const data = PairQrData(
        deviceId: 'dev-abcdef',
        identityPublicKey: 'publicKeyBase64',
      );
      final encoded = PairQrCodec.encode(data);
      expect(encoded.contains('name='), isFalse);
      final decoded = PairQrCodec.decode(encoded);
      expect(decoded.name, '');
      expect(decoded.deviceId, 'dev-abcdef');
    });

    test('URI 参数顺序无关且可含中文昵称', () {
      final decoded = PairQrCodec.decode(
        'couple-space://pair?key=AAAA&name=%E5%B0%8F%E7%BA%A2&deviceId=dev-red',
      );
      expect(decoded.deviceId, 'dev-red');
      expect(decoded.name, '小红');
      expect(decoded.identityPublicKey, 'AAAA');
    });

    test('非法内容抛 FormatException', () {
      expect(() => PairQrCodec.decode('hello'), throwsFormatException);
      expect(
        () => PairQrCodec.decode('https://example.com/pair'),
        throwsFormatException,
      );
      expect(
        () => PairQrCodec.decode('couple-space://pair?name=只有昵称'),
        throwsFormatException,
      );
      expect(
        () => PairQrCodec.decode('couple-space://pair?deviceId=dev&key='),
        throwsFormatException,
      );
    });
  });
}
