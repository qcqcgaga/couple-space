import 'dart:io';
import 'dart:typed_data';

import 'package:couple_space/core/models/image.dart';
import 'package:couple_space/core/storage/image_files.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late DiskImageFileStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('couple_space_image_files');
    store = DiskImageFileStore(root);
  });

  tearDown(() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  });

  ImageMeta meta({String id = 'img1', String fileName = 'photo.jpg', int size = 0}) {
    return ImageMeta(
      id: id,
      noteId: 'n1',
      fileName: fileName,
      sha256: '',
      size: size,
      lwTs: 1,
      lwDevice: 'deviceA',
    );
  }

  test('写入块并随机读取，文件名扩展名落盘', () async {
    final image = meta(size: 6);
    final chunkA = Uint8List.fromList([1, 2, 3]);
    final chunkB = Uint8List.fromList([4, 5, 6]);
    await store.writeChunk(image, 0, chunkA);
    await store.writeChunk(image, 3, chunkB);

    expect(await store.exists(image), isTrue);
    expect(await store.size(image), 6);
    expect(await store.readChunk(image, 0, 3), [1, 2, 3]);
    expect(await store.readChunk(image, 3, 3), [4, 5, 6]);
    expect(File('${root.path}${Platform.pathSeparator}img1.jpg').existsSync(), isTrue);
  });

  test('sha256 与元数据一致、删除后消失', () async {
    final bytes = Uint8List.fromList([10, 20, 30, 40]);
    final image = meta(size: bytes.length);
    await store.writeChunk(image, 0, bytes);

    final hash = await Sha256().hash(bytes);
    final hex = hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(await store.sha256(image), hex);

    await store.delete(image);
    expect(await store.exists(image), isFalse);
    expect(await store.sha256(image), '');
  });

  test('非法扩展名回退 .bin，且父目录自动创建', () async {
    final image = meta(id: 'img2', fileName: '无扩展名');
    await store.writeChunk(image, 0, Uint8List.fromList([1]));
    expect(File('${root.path}${Platform.pathSeparator}img2.bin').existsSync(), isTrue);
  });
}
