import 'package:couple_space/core/sync/chunk_bitmap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChunkBitmap', () {
    test('解析位图文本：缺失/非法按 false 补齐', () {
      expect(ChunkBitmap.parse(null, 3), [false, false, false]);
      expect(ChunkBitmap.parse('1,0', 3), [true, false, false]);
      expect(ChunkBitmap.parse('1,1,1', 5), [true, true, true, false, false]);
    });

    test('文本互转与全 0/全 1', () {
      expect(ChunkBitmap.toText([true, false, true]), '1,0,1');
      expect(ChunkBitmap.allZeroText(4), '0,0,0,0');
      expect(ChunkBitmap.allOneText(3), '1,1,1');
      expect(ChunkBitmap.allZeroText(0), '');
      expect(ChunkBitmap.textIsComplete('1,1,1', 3), isTrue);
      expect(ChunkBitmap.textIsComplete('1,0,1', 3), isFalse);
    });

    test('缺失块序号与已收计数', () {
      expect(ChunkBitmap.missingSequences('1,0,1,0', 4), [1, 3]);
      expect(ChunkBitmap.missingSequences(null, 3), [0, 1, 2]);
      expect(ChunkBitmap.receivedCount('1,0,1,1', 4), 3);
    });

    test('总数不一致时以总数长度为准', () {
      expect(ChunkBitmap.parse('1,1', 1), [true]);
      expect(ChunkBitmap.missingSequences('1,1', 3), [2]);
    });
  });
}
