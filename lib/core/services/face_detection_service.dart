// lib/core/services/face_detection_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart'
    hide FaceLandmark;
import 'package:injectable/injectable.dart';

import 'face_detection_models.dart';

@lazySingleton
class FaceDetectionService {
  FaceDetector? _streamDetector;
  FaceDetector? _staticDetector;
  bool _disposed = false;

  // ── Lazy Detector Construction ─────────────────────────────────────────────

  FaceDetector get _getStreamDetector {
    _assertNotDisposed();
    return _streamDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: true,
        minFaceSize: 0.15,
      ),
    );
  }

  FaceDetector get _getStaticDetector {
    _assertNotDisposed();
    return _staticDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.10,
      ),
    );
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<List<DetectedFace>> detectFromCameraFrame(
    CameraImage cameraImage,
    int sensorOrientation,
  ) async {
    final inputImage =
        _buildInputImageFromCameraImage(cameraImage, sensorOrientation);
    return _runDetection(inputImage, _getStreamDetector);
  }

  Future<List<DetectedFace>> detectFromFile(File file) async {
    final inputImage = InputImage.fromFile(file);
    return _runDetection(inputImage, _getStaticDetector);
  }

  Future<List<DetectedFace>> detectFromBytes({
    required Uint8List bytes,
    required int width,
    required int height,
    required InputImageRotation rotation,
    required InputImageFormat format,
    required int bytesPerRow,
    bool useAccurateMode = false,
  }) async {
    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: bytesPerRow,
      ),
    );
    final detector =
        useAccurateMode ? _getStaticDetector : _getStreamDetector;
    return _runDetection(inputImage, detector);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _streamDetector?.close();
    await _staticDetector?.close();
    _streamDetector = null;
    _staticDetector = null;
    debugPrint('[FaceDetectionService] Disposed.');
  }

  // ── Private: Core Detection ────────────────────────────────────────────────

  Future<List<DetectedFace>> _runDetection(
    InputImage inputImage,
    FaceDetector detector,
  ) async {
    try {
      final faces = await detector.processImage(inputImage);

      if (faces.isEmpty) return const [];

      final sorted = List<Face>.from(faces)
        ..sort((a, b) {
          final aArea = a.boundingBox.width * a.boundingBox.height;
          final bArea = b.boundingBox.width * b.boundingBox.height;
          return bArea.compareTo(aArea);
        });

      // ── Debug: log every detected face ──────────────────────────────────────
      for (int i = 0; i < sorted.length; i++) {
        final f = sorted[i];
        debugPrint(
          '[FaceDetectionService] Face[$i] → '
          'bbox: ${f.boundingBox}, '
          'trackingId: ${f.trackingId}, '
          'smiling: ${f.smilingProbability?.toStringAsFixed(2)}, '
          'leftEye: ${f.leftEyeOpenProbability?.toStringAsFixed(2)}, '
          'rightEye: ${f.rightEyeOpenProbability?.toStringAsFixed(2)}, '
          'yaw: ${f.headEulerAngleY?.toStringAsFixed(1)}, '
          'roll: ${f.headEulerAngleZ?.toStringAsFixed(1)}',
        );
      }

      return sorted.map(_mapToDetectedFace).toList();
    } catch (e, stackTrace) {
      // Log the REAL underlying exception, not just a generic wrapper.
      debugPrint('[FaceDetectionService] ❌ Detection failed!');
      debugPrint('  Error : $e');
      debugPrint('  Stack : $stackTrace');
      throw FaceDetectionException(
        type: FaceDetectionError.detectorFailure,
        message: 'ML Kit threw an exception: $e',
        cause: e,
      );
    }
  }

  // ── Private: InputImage Builder ────────────────────────────────────────────

  /// Converts a Flutter [CameraImage] into an [InputImage] ML Kit can parse.
  ///
  /// Android: converts YUV_420_888 → tightly-packed NV21.
  /// iOS:     passes the BGRA8888 plane directly (no conversion needed).
  InputImage _buildInputImageFromCameraImage(
    CameraImage image,
    int sensorOrientation,
  ) {
    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
        InputImageRotation.rotation0deg;

    if (Platform.isIOS) {
      // iOS camera plugin delivers BGRA8888. Plane 0 is already packed with
      // the correct bytesPerRow — pass it straight through.
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }

    // Android: convert YUV_420_888 → NV21.
    // ML Kit's Android implementation cannot parse the multi-plane layout
    // Flutter exposes. NV21 is the only format it reliably accepts.
    final nv21 = _convertYuv420ToNv21(image);

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        // NV21 is tightly packed — no stride padding.
        bytesPerRow: image.width,
      ),
    );
  }

  /// Converts a [CameraImage] in YUV_420_888 to a tightly-packed NV21 buffer.
  ///
  /// NV21 memory layout:
  ///   [Y₀ Y₁ … Yₙ]          full-res Y plane, row-major, no padding
  ///   [V₀ U₀ V₁ U₁ … ]      half-res VU interleaved (V before U)
  ///
  /// The Flutter camera plugin does NOT expose pixelStride on [Plane].
  /// We infer whether the UV data is planar (pixel-stride=1) or semi-planar
  /// (pixel-stride=2) by comparing the U plane's byte count to the expected
  /// planar size:
  ///
  ///   planar    → uPlane.bytes.length ≈ (width/2) × (height/2)   [stride=1]
  ///   semi-planar → uPlane.bytes.length ≈  width   × (height/2)  [stride=2]
  Uint8List _convertYuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1]; // Cb
    final Plane vPlane = image.planes[2]; // Cr

    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;

    final nv21 = Uint8List(ySize + uvSize);

    // ── 1. Copy Y plane, stripping any row-padding ──────────────────────────
    int dstY = 0;
    for (int row = 0; row < height; row++) {
      nv21.setRange(dstY, dstY + width, yPlane.bytes, row * yPlane.bytesPerRow);
      dstY += width;
    }

    // ── 2. Infer UV pixel stride from the U plane's actual byte count ────────
    //
    // Expected planar size = (width/2) × (height/2).
    // If the actual buffer is larger, the samples are interleaved (stride=2).
    final int uvWidth = width ~/ 2;
    final int uvHeight = height ~/ 2;
    final int expectedPlanarSize = uvWidth * uvHeight;
    // Use stride=2 when the plane is bigger than pure-planar would require.
    final int uvPixelStride = uPlane.bytes.length > expectedPlanarSize ? 2 : 1;

    debugPrint(
      '[FaceDetectionService] UV inference → '
      'uPlane.bytes.length=${uPlane.bytes.length}, '
      'expectedPlanar=$expectedPlanarSize, '
      'inferredPixelStride=$uvPixelStride',
    );

    // ── 3. Interleave V then U → NV21 VU plane ──────────────────────────────
    int dstUV = ySize;
    for (int row = 0; row < uvHeight; row++) {
      final int uRowBase = row * uPlane.bytesPerRow;
      final int vRowBase = row * vPlane.bytesPerRow;
      for (int col = 0; col < uvWidth; col++) {
        // NV21 = V first, then U  (opposite order from NV12).
        nv21[dstUV++] = vPlane.bytes[vRowBase + col * uvPixelStride];
        nv21[dstUV++] = uPlane.bytes[uRowBase + col * uvPixelStride];
      }
    }

    return nv21;
  }

  // ── Private: Type Mappers ──────────────────────────────────────────────────

  DetectedFace _mapToDetectedFace(Face face) {
    return DetectedFace(
      boundingBox: Rect.fromLTRB(
        face.boundingBox.left.toDouble(),
        face.boundingBox.top.toDouble(),
        face.boundingBox.right.toDouble(),
        face.boundingBox.bottom.toDouble(),
      ),
      yawAngle: face.headEulerAngleY,
      rollAngle: face.headEulerAngleZ,
      landmarks: _extractLandmarks(face),
      leftEyeOpenProbability: face.leftEyeOpenProbability,
      rightEyeOpenProbability: face.rightEyeOpenProbability,
      smilingProbability: face.smilingProbability,
      trackingId: face.trackingId,
    );
  }

  Map<FaceLandmark, Offset> _extractLandmarks(Face face) {
    const typeMapping = {
      FaceLandmarkType.leftEye: FaceLandmark.leftEye,
      FaceLandmarkType.rightEye: FaceLandmark.rightEye,
      FaceLandmarkType.leftEar: FaceLandmark.leftEar,
      FaceLandmarkType.rightEar: FaceLandmark.rightEar,
      FaceLandmarkType.leftCheek: FaceLandmark.leftCheek,
      FaceLandmarkType.rightCheek: FaceLandmark.rightCheek,
      FaceLandmarkType.noseBase: FaceLandmark.noseTip,
      FaceLandmarkType.leftMouth: FaceLandmark.mouthLeft,
      FaceLandmarkType.rightMouth: FaceLandmark.mouthRight,
      FaceLandmarkType.bottomMouth: FaceLandmark.mouthBottom,
    };

    final result = <FaceLandmark, Offset>{};
    for (final entry in typeMapping.entries) {
      final mlkitLandmark = face.landmarks[entry.key];
      if (mlkitLandmark != null) {
        result[entry.value] = Offset(
          mlkitLandmark.position.x.toDouble(),
          mlkitLandmark.position.y.toDouble(),
        );
      }
    }
    return result;
  }

  // ── Private: Guards ────────────────────────────────────────────────────────

  void _assertNotDisposed() {
    if (_disposed) {
      throw FaceDetectionException(
        type: FaceDetectionError.disposed,
        message: 'FaceDetectionService has been disposed. '
            'Do not call methods after dispose().',
      );
    }
  }
}