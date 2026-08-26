import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:medusa_admin/src/core/di/di.dart';
import 'package:medusa_admin/src/core/extensions/random_extension.dart';
import 'package:path_provider/path_provider.dart';

@lazySingleton
class ImagePickerHelper {
  final _picker = ImagePicker();
  final _imageCropper = ImageCropper();
  static ImagePickerHelper get instance => getIt<ImagePickerHelper>();

  // A memory cache to store picked image bytes on Web
  static final Map<String, Uint8List> webBytesCache = {};

  Future<File?> imagePicker(
      {required ImageSource source,
      CropStyle? cropStyle,
      CropAspectRatio? cropAspectRatio}) async {
    if (kIsWeb) {
      final pickedImage = await _picker.pickImage(imageQuality: 20, source: source);
      if (pickedImage == null) {
        return null;
      }
      final bytes = await pickedImage.readAsBytes();
      webBytesCache[pickedImage.path] = bytes;
      return File(pickedImage.path);
    }

    Directory appDocDir = await getApplicationDocumentsDirectory();
    final random = Random();
    String imagePath = '${appDocDir.path}/${random.nextIntOfDigits(2)}';

    XFile? pickedImage =
        await _picker.pickImage(imageQuality: 20, source: source);
    if (pickedImage == null) {
      return null;
    }
    await pickedImage.saveTo(imagePath);

    CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: imagePath, aspectRatio: cropAspectRatio);

    if (croppedFile == null) {
      return null;
    }
    await File(imagePath).delete();

    // Safe rename via byte-copy to avoid cross-filesystem errors on Android
    try {
      final bytes = await File(croppedFile.path).readAsBytes();
      final cleanPath = croppedFile.path.replaceAll('image_cropper_', '');
      if (cleanPath != croppedFile.path) {
        final dest = File(cleanPath);
        await dest.writeAsBytes(bytes, flush: true);
        return dest;
      }
    } catch (_) {}
    return File(croppedFile.path);
  }

  Future<List<File>> multipleImagePicker(
      {CropStyle? cropStyle, CropAspectRatio? cropAspectRatio}) async {
    List<XFile>? pickedImage = await _picker.pickMultiImage(imageQuality: 20);

    if (pickedImage == null || pickedImage.isEmpty) {
      return [];
    }
    List<File> images = [];

    for (var element in pickedImage) {
      if (kIsWeb) {
        final bytes = await element.readAsBytes();
        webBytesCache[element.path] = bytes;
        images.add(File(element.path));
      } else {
        // On Android, renameSync across filesystem boundaries throws
        // FileSystemException. Use a safe byte-copy to temp directory instead.
        try {
          final bytes = await element.readAsBytes();
          final tempDir = await getTemporaryDirectory();
          // Use the original filename (without any picker prefix) as the dest name
          final originalName = element.path.split('/').last
              .replaceAll('image_picker_', '');
          final destPath = '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}_$originalName';
          final destFile = File(destPath);
          await destFile.writeAsBytes(bytes, flush: true);
          images.add(destFile);
        } catch (e) {
          // Fallback: use the original path as-is
          images.add(File(element.path));
        }
      }
    }
    return images;
  }

  Future<File?> cropImage(File image,
      {CropStyle? cropStyle, CropAspectRatio? cropAspectRatio}) async {
    if (kIsWeb) {
      return image; // No-op on Web
    }
    CroppedFile? croppedFile = await _imageCropper.cropImage(
        sourcePath: image.path, aspectRatio: cropAspectRatio);

    if (croppedFile == null) {
      return null;
    }
    // Safe rename via byte-copy to avoid cross-filesystem errors on Android
    try {
      final bytes = await File(croppedFile.path).readAsBytes();
      final cleanPath = croppedFile.path.replaceAll('image_cropper_', '');
      if (cleanPath != croppedFile.path) {
        final dest = File(cleanPath);
        await dest.writeAsBytes(bytes, flush: true);
        return dest;
      }
    } catch (_) {}
    return File(croppedFile.path);
  }
}
