import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PhotoPickException implements Exception {
  PhotoPickException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PhotoPickerService {
  PhotoPickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<String?> pickAndSave({required ImageSource source}) async {
    try {
      // Keep profile photos small (~200–300KB) for faster Cloudinary uploads.
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
        requestFullMetadata: false,
      );
      if (file == null) return null;

      final docs = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(docs.path, 'profile_photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext =
          p.extension(file.path).isEmpty ? '.jpg' : p.extension(file.path);
      final destPath = p.join(
        photosDir.path,
        'photo_${DateTime.now().millisecondsSinceEpoch}$ext',
      );

      // Prefer bytes over File.copy — more reliable on iOS temp URLs.
      final bytes = await file.readAsBytes();
      await File(destPath).writeAsBytes(bytes, flush: true);
      return destPath;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied') {
        throw PhotoPickException(
          'Permission denied. Allow camera/photos access in Settings.',
        );
      }
      if (source == ImageSource.camera) {
        throw PhotoPickException(
          'Camera is unavailable. Try Gallery, or use a physical device.',
        );
      }
      throw PhotoPickException(
        e.message ?? 'Could not pick a photo. Please try again.',
      );
    } catch (e) {
      if (e is PhotoPickException) rethrow;
      throw PhotoPickException('Could not save the photo. Please try again.');
    }
  }
}
