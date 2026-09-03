// lib/core/services/classification_service.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hai_app/features/post/data/models/prediction_result.dart';

@lazySingleton
class ClassificationService {
  Interpreter? _interpreter;
  List<String>? _labels;

  static const int _inputSize = 224;
  static const double _threshold = 0.40; // 40% confidence gate

  static Future<List<String>> _loadLabels() async {
    final raw = await rootBundle.loadString('assets/labels.txt');
    // Map through the split list and trim every individual label to destroy hidden \r or whitespace
    return raw.trim().split('\n').map((label) => label.trim()).toList(); // new fix was done here
  }

  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final results = await Future.wait([
        Interpreter.fromAsset('assets/LightModel.tflite'),
        _loadLabels(),
      ]);
      _interpreter = results[0] as Interpreter;
      _labels = results[1] as List<String>;
    } catch (e) {
      rethrow;
    }
  }

  Future<PredictionResult?> classify(File image) async {
    if (_interpreter == null || _labels == null) await loadModel();

    try {
      final rawBytes = await image.readAsBytes();
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return null;

      // Convert/resize to 224x224 RGB (drops alpha channel).
      // Matches Colab's: img.convert('RGB').resize((224, 224))
      final rgb = img.copyResize(
        decoded,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.cubic, // ~PIL Lanczos (close enough)
      );

      // Build input normalized to [0.0, 1.0] in RGB order.
      // MUST match training (train_ds.map: x / 255.0) and the corrected
      // Colab Cell 5. Feeding raw 0-255 floats was the bug that saturated
      // outputs to ~100% and flipped road -> trash.
      final input = List.generate(
        1,
            (_) => List.generate(
          _inputSize,
              (y) => List.generate(
            _inputSize,
                (x) {
              final pixel = rgb.getPixel(x, y);
              return [
                pixel.r / 255.0, // R — 0.0 to 1.0
                pixel.g / 255.0, // G — 0.0 to 1.0
                pixel.b / 255.0, // B — 0.0 to 1.0
                // alpha is deliberately excluded
              ];
            },
          ),
        ),
      );

      final output =
      List.filled(_labels!.length, 0.0).reshape([1, _labels!.length]);

      _interpreter!.run(input, output);

      final probabilities = output[0] as List<double>;
      double maxConf = 0.0;
      int maxIndex = 0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxConf) {
          maxConf = probabilities[i];
          maxIndex = i;
        }
      }

      // Explicit "Other" rejection: the catch-all class means the image isn't
      // a recognizable problem category. Reject before the threshold check so
      // even a high-confidence "Other" is still correctly rejected.
      // Adding a secondary safety trim here to guarantee string matching
      if (_labels![maxIndex].trim().toLowerCase() == 'other') return null; // new fix was done here

      // Confidence gate: recognized a valid category but not confident enough.
      if (maxConf < _threshold) return null;

      return PredictionResult(
        index: maxIndex,
        label: _labels![maxIndex],
        confidence: maxConf,
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
  }
}