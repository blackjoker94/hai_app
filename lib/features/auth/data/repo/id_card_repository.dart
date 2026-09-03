// lib/features/auth/data/repo/id_card_repository.dart

import 'dart:io';
import 'package:injectable/injectable.dart';
import 'package:hai_app/core/services/face_detection_models.dart';
import 'package:hai_app/core/services/face_detection_service.dart';
import 'package:hai_app/core/services/image_service.dart';

// ── Failure ───────────────────────────────────────────────────────────────────

class IdCardFailure {
  final String message;
  final IdCardFailureType type;

  IdCardFailure._(this.message, this.type);

  factory IdCardFailure.cancelled() => IdCardFailure._(
        'تم إلغاء اختيار الصورة',
        IdCardFailureType.cancelled,
      );

  factory IdCardFailure.noFace() => IdCardFailure._(
        'لم يتم العثور على وجه في صورة البطاقة.\n'
        'تأكد من وضوح الصورة وظهور الوجه بشكل كامل',
        IdCardFailureType.noFace,
      );

  factory IdCardFailure.multipleFaces() => IdCardFailure._(
        'تم اكتشاف أكثر من وجه في الصورة.\n'
        'يرجى رفع صورة بطاقتك الشخصية فقط',
        IdCardFailureType.multipleFaces,
      );

  factory IdCardFailure.detectionError(String cause) => IdCardFailure._(
        'حدث خطأ أثناء تحليل الصورة: $cause',
        IdCardFailureType.detectionError,
      );
}

enum IdCardFailureType {
  cancelled,
  noFace,
  multipleFaces,
  detectionError,
}

// ── Result ────────────────────────────────────────────────────────────────────

/// Returned on success. Bundles the file with its detected face so the
/// cubit/screen never need to call the repo a second time for the overlay.
class IdCardResult {
  final File imageFile;
  final DetectedFace face;

  const IdCardResult({required this.imageFile, required this.face});
}

// ── Interface ─────────────────────────────────────────────────────────────────

abstract class IdCardRepository {
  /// Opens the gallery picker, then runs face detection on the chosen image.
  ///
  /// Returns [IdCardFailure] when:
  ///   • the user cancels the picker
  ///   • no face is found on the card
  ///   • more than one face is found
  ///   • ML Kit throws internally
  Future<(IdCardFailure?, IdCardResult?)> pickAndDetect();
}

// ── Implementation ────────────────────────────────────────────────────────────

@LazySingleton(as: IdCardRepository)
class IdCardRepositoryImpl implements IdCardRepository {
  final ImageService _imageService;
  final FaceDetectionService _faceDetectionService;

  IdCardRepositoryImpl(this._imageService, this._faceDetectionService);

  @override
  Future<(IdCardFailure?, IdCardResult?)> pickAndDetect() async {
    // ── Step 1: Pick image from gallery ──────────────────────────────────────
    final File? file = await _imageService.pickImage(
      fromCamera: false,
      imageQuality: 100, // full quality — ML Kit needs the detail
    );

    if (file == null) {
      // null means the user tapped back in the picker — not a real error.
      return (IdCardFailure.cancelled(), null);
    }

    // ── Step 2: Run face detection (ACCURATE mode via detectFromFile) ─────────
    try {
      final faces = await _faceDetectionService.detectFromFile(file);

      if (faces.isEmpty) {
        return (IdCardFailure.noFace(), null);
      }

      // Egyptian ID cards have exactly one face photo.
      // detectFromFile already sorts by area (largest first), so index 0
      // is the face we want even if something slipped through the min-size filter.
      if (faces.length > 1) {
        return (IdCardFailure.multipleFaces(), null);
      }

      return (null, IdCardResult(imageFile: file, face: faces.first));
    } on FaceDetectionException catch (e) {
      return (IdCardFailure.detectionError(e.message), null);
    } catch (e) {
      return (IdCardFailure.detectionError(e.toString()), null);
    }
  }
}