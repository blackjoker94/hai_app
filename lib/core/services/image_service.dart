// lib/services/image_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImage({bool fromCamera = false, int? imageQuality = 100}) async {
    final XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: imageQuality,
      );
    } catch (e) {
      return null;
    }
    return picked == null ? null : File(picked.path);
  }

  /// Call at startup to recover images if Android killed your activity.
  Future<List<File>> retrieveLostImages() async {
    final lost = await _picker.retrieveLostData();
    final files = <File>[];
    if (lost.isEmpty) return files;

    if (lost.files != null) {
      for (final xf in lost.files!) {
        files.add(File(xf.path));
      }
    }
    // If lost.exception != null, you can log/report it.
    return files;
  }
}
