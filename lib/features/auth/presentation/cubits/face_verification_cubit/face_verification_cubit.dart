// lib/features/auth/presentation/cubits/face_verification_cubit/face_verification_cubit.dart

import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'package:hai_app/core/services/face_detection_models.dart';
import 'package:hai_app/features/auth/data/repo/face_verification_repository.dart';

part 'face_verification_state.dart';

@injectable
class FaceVerificationCubit extends Cubit<FaceVerificationState> {
  final FaceVerificationRepository _repository;

  // Frame-rate throttle — we don't need to run ML Kit at 30 fps.
  static const int _frameIntervalMs = 150;
  int _lastFrameTimestamp = 0;
  bool _isProcessing = false;

  FaceVerificationCubit(this._repository) : super(FaceVerificationInitial());

  // ── Stage 1: ID card (SelfieScreen calls this in initState) ───────────────

  /// Extracts and stores the face embedding from the confirmed ID card image.
  /// Runs as a background task while the user reads the selfie instructions.
  Future<void> processIdCard(File idCardFile) async {
    emit(FaceVerificationIdProcessing());

    final (failure, success) = await _repository.processIdCard(idCardFile);

    if (isClosed) return;

    if (failure != null) {
      debugPrint('[FaceVerificationCubit] ❌ ID processing: ${failure.message}');
      emit(FaceVerificationError(failure.message));
    } else if (success == true) {
      debugPrint('[FaceVerificationCubit] ✅ ID embedding ready');
      emit(FaceVerificationIdReady());
    }
  }

  // ── Stage 2: Live camera detection (SelfieCameraScreen calls this) ─────────

  /// Called every frame from the camera image stream.
  /// Silently dropped when:
  ///   • the frame rate limiter hasn't elapsed
  ///   • the detector is already busy (_isProcessing)
  ///   • the cubit is in a state that doesn't need live detection
  void onCameraFrame(CameraImage frame) async {
    // Stop processing once a photo is captured or the comparison has started.
    if (state is FaceVerificationCapturing  ||
        state is FaceVerificationPhotoCaptured ||
        state is FaceVerificationComparing   ||
        state is FaceVerificationMatchSuccess ||
        state is FaceVerificationMatchFailed) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (_isProcessing || (now - _lastFrameTimestamp) < _frameIntervalMs) return;

    _isProcessing = true;
    _lastFrameTimestamp = now;

    debugPrint(
      '[FaceVerificationCubit] Frame '
      '${frame.width}×${frame.height} '
      'planes: ${frame.planes.length}',
    );

    final (failure, face) = await _repository.detectLiveFace(frame);

    if (isClosed) return;

    if (failure != null) {
      debugPrint('[FaceVerificationCubit] ❌ ${failure.message}');
      // Only emit error for real failures — "no face found" is normal.
      emit(FaceVerificationError(failure.message));
    } else if (face != null) {
      debugPrint(
        '[FaceVerificationCubit] ✅ Face '
        'trackingId:${face.trackingId} '
        'eyesOpen:${face.areEyesOpen()} '
        'smiling:${face.smilingProbability?.toStringAsFixed(2)}',
      );
      emit(FaceVerificationFaceDetected(face));
    } else {
      emit(FaceVerificationInitial());
    }

    _isProcessing = false;
  }

  /// Called immediately when the shutter button is tapped, BEFORE
  /// the async takePicture() call, so no frames are processed during
  /// the hardware shutter delay.
  void onCapturing() => emit(FaceVerificationCapturing());

  /// Called by SelfieCameraScreen after takePicture() succeeds.
  void onPhotoCaptured(XFile photo) {
    debugPrint('[FaceVerificationCubit] 📸 Photo → ${photo.path}');
    emit(FaceVerificationPhotoCaptured(photo));
  }

  /// Called when the user taps "Retake" — resets to initial so the
  /// live stream resumes detection.
  void onRetake() {
    debugPrint('[FaceVerificationCubit] 🔄 Retake');
    emit(FaceVerificationInitial());
  }

  // ── Stage 3: Comparison (SelfieScreen calls this after selfie confirmed) ───

  /// Compares [selfie] against the ID embedding stored in Stage 1.
  /// Emits [FaceVerificationMatchSuccess] when score ≥ 75 %,
  ///       [FaceVerificationMatchFailed] otherwise.
  Future<void> performComparison(XFile selfie) async {
    emit(FaceVerificationComparing());

    final (failure, score) = await _repository.compareSelfie(
      File(selfie.path),
    );

    if (isClosed) return;

    if (failure != null) {
      debugPrint('[FaceVerificationCubit] ❌ Comparison: ${failure.message}');
      emit(FaceVerificationError(failure.message));
    } else if (score != null) {
      debugPrint(
        '[FaceVerificationCubit] Score: ${score.toStringAsFixed(1)} %',
      );
      if (score >= 75.0) {
        emit(FaceVerificationMatchSuccess(score));
      } else {
        emit(FaceVerificationMatchFailed(score));
      }
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  Future<void> close() {
    // Always wipe the ID embedding when the flow ends — success, failure,
    // or back-navigation — so it can't bleed into the next session.
    _repository.clearSession();
    return super.close();
  }
}