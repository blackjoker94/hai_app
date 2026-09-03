// lib/services/face_detection_models.dart

import 'dart:ui' show Offset, Rect;

// ─────────────────────────────────────────────────────────────────────────────
// DetectedFace
//
// The ONLY face type your repo and cubit will ever touch.
// Zero ML Kit types leak past the service boundary — this is intentional.
// If ML Kit is ever swapped for MediaPipe, this model stays identical.
// ─────────────────────────────────────────────────────────────────────────────

class DetectedFace {
  /// Bounding box in image-pixel coordinates (origin = top-left of source image).
  final Rect boundingBox;

  /// Head yaw (rotation around the vertical axis, ± from center).
  /// Positive = face turned right. Null if not computed by detector.
  final double? yawAngle;

  /// Head roll (tilt sideways, ± from upright).
  /// Positive = head tilted counter-clockwise. Null if not computed.
  final double? rollAngle;

  /// Detected landmark positions, keyed by [FaceLandmark].
  /// Only landmarks actually detected are present — always guard with `[]?`.
  final Map<FaceLandmark, Offset> landmarks;

  /// Probability the left eye is open. Range [0.0, 1.0].
  /// Only available when classification was enabled on the detector.
  final double? leftEyeOpenProbability;

  /// Probability the right eye is open. Range [0.0, 1.0].
  final double? rightEyeOpenProbability;

  /// Probability the person is smiling. Range [0.0, 1.0].
  final double? smilingProbability;

  /// Stable tracking ID assigned by ML Kit across frames.
  /// Only set when face tracking is enabled (stream detector).
  final int? trackingId;

  const DetectedFace({
    required this.boundingBox,
    required this.landmarks,
    this.yawAngle,
    this.rollAngle,
    this.leftEyeOpenProbability,
    this.rightEyeOpenProbability,
    this.smilingProbability,
    this.trackingId,
  });

  // ── Convenience accessors ────────────────────────────────────────────────

  Offset? get leftEyePosition  => landmarks[FaceLandmark.leftEye];
  Offset? get rightEyePosition => landmarks[FaceLandmark.rightEye];
  Offset? get noseTipPosition  => landmarks[FaceLandmark.noseTip];

  /// True when both eye landmarks are available — required for affine alignment.
  bool get hasEyeLandmarks =>
      landmarks.containsKey(FaceLandmark.leftEye) &&
      landmarks.containsKey(FaceLandmark.rightEye);

  /// True when both eye-open probabilities cross the [threshold].
  /// Use this for basic blink-based liveness checks.
  bool areEyesOpen({double threshold = 0.5}) =>
      (leftEyeOpenProbability ?? 1.0) > threshold &&
      (rightEyeOpenProbability ?? 1.0) > threshold;

  /// Convenience: bounding box area in square pixels.
  double get area => boundingBox.width * boundingBox.height;

  @override
  String toString() => 'DetectedFace('
      'bbox: $boundingBox, '
      'yaw: ${yawAngle?.toStringAsFixed(1)}, '
      'roll: ${rollAngle?.toStringAsFixed(1)}, '
      'landmarks: ${landmarks.length}, '
      'trackingId: $trackingId)';
}

// ─────────────────────────────────────────────────────────────────────────────
// FaceLandmark enum
//
// ML Kit's FaceLandmarkType is not exposed beyond the service layer.
// Naming follows anatomical convention (not ML Kit's camelCase abbreviations).
// ─────────────────────────────────────────────────────────────────────────────

enum FaceLandmark {
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftCheek,
  rightCheek,
  noseTip,
  mouthLeft,
  mouthRight,
  mouthBottom,
}

// ─────────────────────────────────────────────────────────────────────────────
// FaceDetectionException
//
// Thrown by FaceDetectionService on non-recoverable errors.
// The repository maps this to a domain failure via try/catch.
// ─────────────────────────────────────────────────────────────────────────────

class FaceDetectionException implements Exception {
  final FaceDetectionError type;
  final String message;
  final Object? cause;

  const FaceDetectionException({
    required this.type,
    required this.message,
    this.cause,
  });

  @override
  String toString() => 'FaceDetectionException(${type.name}): $message'
      '${cause != null ? ' — caused by: $cause' : ''}';
}

enum FaceDetectionError {
  /// Camera image format is not supported (e.g., not YUV_420_888).
  unsupportedFormat,

  /// ML Kit detector threw internally.
  detectorFailure,

  /// Service was used after dispose() was called.
  disposed,
}