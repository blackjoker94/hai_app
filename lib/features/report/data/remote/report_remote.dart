// lib/features/report/data/remote/report_remote.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:hai_app/core/services/firebase_auth_service.dart';
import 'package:hai_app/features/home/data/models/report_model.dart';
import 'package:injectable/injectable.dart';

@injectable
class PostsRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  PostsRemoteDataSource(this._firestore, this._authService);

  Future<List<Report>> fetchUserPosts() async {
    try {
      final uid = _authService.currentUserId;
      if (uid == null) return [];

      final querySnapshot = await _firestore
          .collection('posts')
          .where('creatorId', isEqualTo: uid)
          .get();

      final reports = querySnapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();

      // Sort newest first
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    } catch (e) {
      throw ServerFailure('فشل تحميل البلاغات: ${e.toString()}');
    }
  }

  Future<List<Report>> fetchAllPosts() async {
    try {
      final querySnapshot = await _firestore.collection('posts').get();

      final reports = querySnapshot.docs.map((doc) => Report.fromFirestore(doc)).toList();

      // Sort newest first
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return reports;
    } catch (e) {
      throw ServerFailure('فشل تحميل البلاغات: ${e.toString()}');
    }
  }
}