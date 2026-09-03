import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Report extends Equatable {
  final String id;
  final String rawTitle; // trash | road | flood
  final String imageUrl;
  final String status;
  final String createdAt;

  const Report({
    required this.id,
    required this.rawTitle,
    required this.imageUrl,
    required this.status,
    required this.createdAt,
  });

  String get displayTitle {
    switch (rawTitle.toLowerCase()) {
      case 'trash':
        return 'مشكلة القمامة في الحي';
      case 'flood':
        return 'مشكلة الصرف الصحي في الحي';
      case 'road':
        return 'مشكلة في الطريق في الحي';
      default:
        return rawTitle;
    }
  }

  String get title => displayTitle;

  String get ticketNumber =>
      'رقم الشكوى ${id.length >= 6 ? id.substring(id.length - 6) : id}';

  bool get isCompleted =>
      status == 'تم التصليح' || status == 'تم حل المشكلة يا بطل';

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return createdAt;
    }
  }

  factory Report.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String createdDateStr = '';
    final createdAtRaw = data['createdAt'];
    if (createdAtRaw is Timestamp) {
      createdDateStr = createdAtRaw.toDate().toIso8601String();
    } else if (createdAtRaw is String) {
      createdDateStr = createdAtRaw;
    } else {
      createdDateStr = DateTime.now().toIso8601String();
    }

    return Report(
      id: doc.id,
      rawTitle: data['title'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'قيد المراجعه',
      createdAt: createdDateStr,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['_id'] ?? json['id']) as String? ?? '',
      rawTitle: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'قيد المراجعه',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, rawTitle, imageUrl, status, createdAt];
}