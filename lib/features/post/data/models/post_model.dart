import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String imageUrl;
  final double lat;
  final double lng;
  final String creatorId;
  final int userPoints;
  final String creatorName;

  PostModel({
    required this.id,
    required this.imageUrl,
    required this.lat,
    required this.lng,
    required this.creatorId,
    required this.userPoints,
    required this.creatorName,
  });

  factory PostModel.fromFirestore({
    required DocumentSnapshot doc,
    required int userPoints,
    required String creatorName,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final location = data['location'] as Map<String, dynamic>? ?? {};

    return PostModel(
      id: doc.id,
      imageUrl: data['imageUrl'] as String? ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['long'] as num?)?.toDouble() ?? (location['lng'] as num?)?.toDouble() ?? 0.0,
      creatorId: data['creatorId'] as String? ?? '',
      userPoints: userPoints,
      creatorName: data['creatorName'] as String? ?? creatorName,
    );
  }

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final post = (json['post'] as Map<String, dynamic>?) ?? json;
    final creator = json['creator'] as Map<String, dynamic>?;
    final location = post['location'] as Map<String, dynamic>? ?? {};

    return PostModel(
      id: (post['_id'] ?? post['id']) as String? ?? '',
      imageUrl: post['imageUrl'] as String? ?? '',
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['long'] as num?)?.toDouble() ?? (location['lng'] as num?)?.toDouble() ?? 0.0,
      creatorId: (post['creatorId'] ?? post['creator']) as String? ?? '',
      userPoints: (json['userPoints'] as num?)?.toInt() ?? 0,
      creatorName: creator?['name'] as String? ?? (post['creatorName'] as String? ?? ''),
    );
  }
}