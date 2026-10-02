import 'package:image_picker/image_picker.dart';

import '../services/note_service.dart';

/// 图片选择抽象：生产用系统相册/相机，测试注入假实现。
abstract interface class ImagePickerBridge {
  Future<List<PickedImage>> pickFromGallery();

  Future<PickedImage?> pickFromCamera();
}

/// 系统实现：image_picker 多选相册 / 拍照（Android/iOS 原生插件）。
class SystemImagePicker implements ImagePickerBridge {
  SystemImagePicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedImage>> pickFromGallery() async {
    final files = await _picker.pickMultiImage();
    return [
      for (final file in files)
        PickedImage(sourcePath: file.path, fileName: file.name),
    ];
  }

  @override
  Future<PickedImage?> pickFromCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    return file == null
        ? null
        : PickedImage(sourcePath: file.path, fileName: file.name);
  }
}
