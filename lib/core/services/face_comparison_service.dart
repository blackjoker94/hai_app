// lib/core/services/face_comparison_service.dart

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'face_detection_models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FaceComparisonService
//
// Wraps the mobilefacenet.tflite model. Converts a face crop into a
// 192-dimensional embedding, then measures Euclidean distance between
// two embeddings to produce a [0–100] similarity score.
//
// Model constants verified against:
//   github.com/MCarlomagno/FaceRecognitionAuth — MLService.dart
//
//   Input  : [1, 112, 112, 3]  float32, pixels in [-1, 1]
//   Output : [1, 192]          float32, L2-normalized embedding
//
// Normalization: (pixel - 128) / 128  — NOT (pixel - 127.5) / 128.
// The reference project uses integer 128; matching it exactly avoids a
// systematic bias that would lower all similarity scores.
// ─────────────────────────────────────────────────────────────────────────────

@lazySingleton
class FaceComparisonService {
  Interpreter? _interpreter;
  bool _disposed = false;

  static const int _inputSize = 112;
  static const int _embeddingSize = 192;

  // ── Empirical match threshold ──────────────────────────────────────────────
  //
  // The reference project uses 0.5 as its "same person" Euclidean threshold.
  // For the score mapping below we use 0.9 as the "zero confidence" boundary,
  // giving room between a bare pass (0.5 distance ≈ 44% score) and the
  // 75% cutoff (0.225 distance).
  //
  // TUNE THIS after testing real Egyptian ID cards:
  //   - print actual distances to the debug console
  //   - lower _matchThreshold tightens the mapping (higher false-reject rate)
  //   - raise it relaxes it (higher false-accept rate)
  static const double _matchThreshold = 0.9;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_interpreter != null || _disposed) return;

    try {
      Delegate? delegate;

      if (Platform.isAndroid) {
        // Simplified for newer tflite_flutter versions
        delegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(isPrecisionLossAllowed: false),
        );
      } else if (Platform.isIOS) {
        // Simplified for iOS as well to prevent similar enum errors
        delegate = GpuDelegate(
          options: GpuDelegateOptions(allowPrecisionLoss: true),
        );
      }

      final options = InterpreterOptions();
      if (delegate != null) options.addDelegate(delegate);

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );

      final outputShape = _interpreter!.getOutputTensor(0).shape;
      debugPrint(
        '[FaceComparisonService] ✅ Model loaded. '
        'Output shape: $outputShape',
      );
    } catch (e) {
      debugPrint(
        '[FaceComparisonService] ⚠️ GPU delegate failed ($e). '
        'Falling back to CPU.',
      );
      _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Crops the face from [imageFile] using [face].boundingBox, resizes it to
  /// 112×112, normalises pixels to [−1, 1], runs the model, and returns the
  /// raw 192-dim embedding vector.
  Future<List<double>> getEmbedding(File imageFile, DetectedFace face) async {
    _assertReady();

    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception(
        '[FaceComparisonService] Cannot decode: ${imageFile.path}',
      );
    }

    // ── 1. Crop with a safety margin ──────────────────────────────────────
    // The reference project adds ±10 px so the full face (including hairline
    // and chin) is always included. Clamp to image bounds to avoid crashes.
    const double margin = 10.0;
    final bbox = face.boundingBox;

    final x = (bbox.left - margin)
        .clamp(0.0, image.width.toDouble() - 1)
        .toInt();
    final y = (bbox.top - margin)
        .clamp(0.0, image.height.toDouble() - 1)
        .toInt();
    final w = (bbox.width + margin * 2)
        .clamp(1.0, (image.width - x).toDouble())
        .toInt();
    final h = (bbox.height + margin * 2)
        .clamp(1.0, (image.height - y).toDouble())
        .toInt();

    final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);

    // ── 2. Square-resize to 112×112 ───────────────────────────────────────
    // copyResizeCropSquare pads/crops to a square first, THEN resizes.
    // This matches the reference and avoids aspect-ratio distortion.
    final resized = img.copyResizeCropSquare(cropped, size: _inputSize);

    // ── 3. Normalise: (pixel - 128) / 128  →  [-1, 1] ────────────────────
    final input = Float32List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int row = 0; row < _inputSize; row++) {
      for (int col = 0; col < _inputSize; col++) {
        final pixel = resized.getPixel(col, row);
        input[idx++] = (pixel.r.toDouble() - 128.0) / 128.0;
        input[idx++] = (pixel.g.toDouble() - 128.0) / 128.0;
        input[idx++] = (pixel.b.toDouble() - 128.0) / 128.0;
      }
    }

    // ── 4. Run inference ──────────────────────────────────────────────────
    // Reshape to [1, 112, 112, 3] — tflite_flutter needs a nested List.
    final inputTensor = input.reshape([1, _inputSize, _inputSize, 3]);
    final output = List.generate(1, (_) => List.filled(_embeddingSize, 0.0));

    _interpreter!.run(inputTensor, output);

    debugPrint(
      '[FaceComparisonService] Embedding extracted '
      '(first 4 dims): ${output[0].take(4).map((v) => v.toStringAsFixed(4)).toList()}',
    );

    return List<double>.from(output[0]);
  }

  /// Computes Euclidean distance between [emb1] and [emb2], then maps it to a
  /// [0.0 – 100.0] percentage where 100 = identical and 0 = completely different.
  ///
  /// Mapping:  score = clamp((1 − distance / _matchThreshold) × 100, 0, 100)
  ///
  ///   distance 0.00  → 100 %
  ///   distance 0.225 →  75 %   ← your pass threshold
  ///   distance 0.45  →  50 %
  ///   distance 0.90  →   0 %
  /// Computes Euclidean distance between [emb1] and [emb2], then maps it to a
  /// [0.0 – 100.0] percentage. Tuned specifically for ID Cards vs Live Selfies.
  double computeSimilarityScore(List<double> emb1, List<double> emb2) {
    final distance = _euclideanDistance(emb1, emb2);

    // ID Card vs Live Selfie inherently yields a higher distance than Selfie vs Selfie
    // because of lighting, paper texture, watermarks, and photo aging.
    //
    // Typical FaceNet distances:
    // 0.00 - 0.60: Identical high-quality photos
    // 0.60 - 1.15: Same person, varying quality (ID card vs live selfie)
    // 1.15 - 1.50: Different people

    double score = 0.0;
    if (distance <= 0.6) {
      // Map excellent matches [0.0 -> 0.6] to [85% -> 100%]
      score = 85.0 + ((0.6 - distance) / 0.6) * 15.0;
    } else if (distance <= 1.15) {
      // Map acceptable matches [0.6 -> 1.15] to [75% -> 85%] (75% is your pass threshold)
      score = 75.0 + ((1.15 - distance) / 0.55) * 10.0;
    } else {
      // Map mismatches [1.15 -> 1.5] to [0% -> 75%]
      score = 75.0 - ((distance - 1.15) / 0.35) * 75.0;
    }

    final clamped = score.clamp(0.0, 100.0);

    debugPrint(
      '[FaceComparisonService] '
      'Distance: ${distance.toStringAsFixed(4)} -> '
      'Score: ${clamped.toStringAsFixed(1)}%',
    );

    return clamped;
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _interpreter?.close();
    _interpreter = null;
    debugPrint('[FaceComparisonService] Disposed.');
  }

  // ── Private ────────────────────────────────────────────────────────────────

  double _euclideanDistance(List<double> a, List<double> b) {
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      final diff = a[i] - b[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  void _assertReady() {
    if (_disposed) {
      throw StateError(
        'FaceComparisonService has been disposed. '
        'Do not call methods after dispose().',
      );
    }
    if (_interpreter == null) {
      throw StateError(
        'FaceComparisonService.init() was not awaited before use.',
      );
    }
  }
}
