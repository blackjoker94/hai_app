

class PredictionResult {
  final int index;
  final String label;
  final double confidence;

  PredictionResult({
    required this.index,
    required this.label,
    required this.confidence,
  });

  factory PredictionResult.fromMap(Map<String, dynamic> map) {
    return PredictionResult(
      index: map['index'] as int,
      label: (map['label'] as String).replaceAll(RegExp(r'^\d+\s*'), '').trim(),
      confidence: (map['confidence'] as num).toDouble(),
    );
  }


  String get arabicLabel {
    switch (label.toLowerCase()) {
      case 'flood':
        return 'فيضان';
      case 'road':
        return 'تلف في الطريق';
      case 'trash':
        return 'قمامة';
      default:
        return label;
    }
  }

  String get confidencePercent =>
      '${(confidence * 100).toStringAsFixed(1)}%';
}