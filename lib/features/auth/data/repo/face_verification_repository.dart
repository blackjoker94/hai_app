// lib/features/auth/data/repo/face_verification_repository.dart

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:hai_app/core/services/camera_service.dart';
import 'package:hai_app/core/services/face_comparison_service.dart';
import 'package:hai_app/core/services/face_detection_models.dart';
import 'package:hai_app/core/services/face_detection_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Failure model
// ─────────────────────────────────────────────────────────────────────────────

class FaceVerificationFailure {
  final String message;
  const FaceVerificationFailure._(this.message);

  factory FaceVerificationFailure.noFace() =>
      const FaceVerificationFailure._('لم يتم اكتشاف وجه');

  factory FaceVerificationFailure.multipleFaces() =>
      const FaceVerificationFailure._(
        'تم اكتشاف أكثر من وجه، يرجى التأكد من ظهور وجهك فقط',
      );

  factory FaceVerificationFailure.idNotProcessed() =>
      const FaceVerificationFailure._(
        'يرجى معالجة البطاقة أولاً قبل المقارنة',
      );

  factory FaceVerificationFailure.cameraUnavailable() =>
      const FaceVerificationFailure._('الكاميرا غير مفعلة');

  factory FaceVerificationFailure.error(String msg) =>
      FaceVerificationFailure._(msg);
}

// ─────────────────────────────────────────────────────────────────────────────
// Interface
// ─────────────────────────────────────────────────────────────────────────────

abstract class FaceVerificationRepository {
  /// Detects a single face from a live camera frame.
  Future<(FaceVerificationFailure?, DetectedFace?)> detectLiveFace(
    CameraImage frame,
  );

  /// Extracts and stores the face embedding from the confirmed ID card image.
  /// Must be called before [compareSelfie].
  Future<(FaceVerificationFailure?, bool)> processIdCard(File idCardFile);

  /// Compares a selfie against the previously stored ID embedding.
  /// Returns a similarity score [0.0 – 100.0].
  Future<(FaceVerificationFailure?, double?)> compareSelfie(File selfieFile);

  /// Clears the stored ID embedding. Call when the verification flow ends
  /// (success, failure, or cancellation) to avoid stale data leaking
  /// into the next session.
  void clearSession();
}

// ─────────────────────────────────────────────────────────────────────────────
// Implementation
// ─────────────────────────────────────────────────────────────────────────────

@LazySingleton(as: FaceVerificationRepository)
class FaceVerificationRepositoryImpl implements FaceVerificationRepository {
  final FaceDetectionService _detectionService;
  final FaceComparisonService _comparisonService;
  final CameraService _cameraService;

  /// The 192-dim embedding extracted from the ID card face.
  /// Null until [processIdCard] succeeds.
  List<double>? _idEmbedding;

  FaceVerificationRepositoryImpl(
    this._detectionService,
    this._comparisonService,
    this._cameraService,
  );

  // ── Live detection ─────────────────────────────────────────────────────────

  @override
  Future<(FaceVerificationFailure?, DetectedFace?)> detectLiveFace(
    CameraImage frame,
  ) async {
    try {
      final controller = _cameraService.controller;
      if (controller == null) {
        return (FaceVerificationFailure.cameraUnavailable(), null);
      }

      // Use the real sensor orientation from the camera description —
      // not a hardcoded 90° which breaks on many devices.
      final sensorOrientation = controller.description.sensorOrientation;

      final faces = await _detectionService.detectFromCameraFrame(
        frame,
        sensorOrientation,
      );

      if (faces.isEmpty) return (FaceVerificationFailure.noFace(), null);
      if (faces.length > 1) return (FaceVerificationFailure.multipleFaces(), null);

      return (null, faces.first);
    } on FaceDetectionException catch (e) {
      return (FaceVerificationFailure.error(e.message), null);
    } catch (e) {
      return (FaceVerificationFailure.error(e.toString()), null);
    }
  }

  // ── ID card processing ─────────────────────────────────────────────────────

  @override
  Future<(FaceVerificationFailure?, bool)> processIdCard(
    File idCardFile,
  ) async {
    try {
      // detectFromFile uses ACCURATE mode — best for static ID card photos.
      final faces = await _detectionService.detectFromFile(idCardFile);

      if (faces.isEmpty) return (FaceVerificationFailure.noFace(), false);

      // Init lazily so we only pay the GPU init cost when actually needed.
      await _comparisonService.init();

      _idEmbedding = await _comparisonService.getEmbedding(
        idCardFile,
        faces.first,
      );

      debugPrint(
        '[FaceVerificationRepository] ✅ ID embedding extracted '
        '(${_idEmbedding!.length} dims)',
      );

      return (null, true);
    } on FaceDetectionException catch (e) {
      return (FaceVerificationFailure.error(e.message), false);
    } catch (e) {
      return (FaceVerificationFailure.error(e.toString()), false);
    }
  }

  // ── Selfie comparison ──────────────────────────────────────────────────────

  @override
  Future<(FaceVerificationFailure?, double?)> compareSelfie(
    File selfieFile,
  ) async {
    if (_idEmbedding == null) {
      return (FaceVerificationFailure.idNotProcessed(), null);
    }

    try {
      // Use ACCURATE mode on the captured selfie too — it's a static file
      // at this point, not a live frame, so speed is not a concern.
      final faces = await _detectionService.detectFromFile(selfieFile);

      if (faces.isEmpty) return (FaceVerificationFailure.noFace(), null);

      final selfieEmbedding = await _comparisonService.getEmbedding(
        selfieFile,
        faces.first,
      );

      final score = _comparisonService.computeSimilarityScore(
        _idEmbedding!,
        selfieEmbedding,
      );

      return (null, score);
    } on FaceDetectionException catch (e) {
      return (FaceVerificationFailure.error(e.message), null);
    } catch (e) {
      return (FaceVerificationFailure.error(e.toString()), null);
    }
  }

  // ── Session management ─────────────────────────────────────────────────────

  @override
  void clearSession() {
    _idEmbedding = null;
    debugPrint('[FaceVerificationRepository] Session cleared.');
  }
}