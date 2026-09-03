// lib/features/auth/presentation/cubits/face_verification_cubit/face_verification_state.dart

part of 'face_verification_cubit.dart';

abstract class FaceVerificationState {}

// ── Camera / detection states (used by SelfieCameraScreen) ──────────────────

/// Idle — no face in frame yet, or after a retake.
class FaceVerificationInitial extends FaceVerificationState {}

/// Face found in the live stream — shutter button activates.
class FaceVerificationFaceDetected extends FaceVerificationState {
  final DetectedFace face;
  FaceVerificationFaceDetected(this.face);
}

/// Hardware shutter has fired — drop all incoming frames.
class FaceVerificationCapturing extends FaceVerificationState {}

/// Photo taken — preview mode, user can confirm or retake.
class FaceVerificationPhotoCaptured extends FaceVerificationState {
  final XFile photo;
  FaceVerificationPhotoCaptured(this.photo);
}

// ── ID card processing states (used by SelfieScreen) ────────────────────────

/// TFLite is extracting the embedding from the ID card image.
class FaceVerificationIdProcessing extends FaceVerificationState {}

/// ID embedding extracted successfully — camera button can be enabled.
class FaceVerificationIdReady extends FaceVerificationState {}

// ── Comparison states ────────────────────────────────────────────────────────

/// Comparing selfie embedding against the stored ID embedding.
class FaceVerificationComparing extends FaceVerificationState {}

/// Similarity score ≥ 75 % — faces match.
class FaceVerificationMatchSuccess extends FaceVerificationState {
  final double matchScore;
  FaceVerificationMatchSuccess(this.matchScore);
}

/// Similarity score < 75 % — faces do not match.
class FaceVerificationMatchFailed extends FaceVerificationState {
  final double matchScore;
  FaceVerificationMatchFailed(this.matchScore);
}

// ── Error state (used across all stages) ────────────────────────────────────

class FaceVerificationError extends FaceVerificationState {
  final String message;
  FaceVerificationError(this.message);
}