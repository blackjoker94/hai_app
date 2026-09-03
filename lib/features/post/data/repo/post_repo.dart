import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:hai_app/core/services/cloudinary_service.dart';
import 'package:hai_app/core/services/firebase_auth_service.dart';
import 'package:hai_app/features/post/data/models/post_model.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PostRepo {
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;
  final FlutterSecureStorage _storage;
  final CloudinaryService _cloudinaryService;

  PostRepo(
    this._firestore,
    this._authService,
    this._storage,
    this._cloudinaryService,
  );

  Future<PostModel> createPost({
    required File image,
    required double lat,
    required double lng,
    required String title,
  }) async {
    try {
      final user = _authService.currentUser;
      final userId = user?.uid;
      if (userId == null) {
        throw const ServerFailure('يجب تسجيل الدخول لإنشاء بلاغ');
      }

      // 1. Upload image to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(image);

      // 2. Fetch user name
      final userName = await _storage.read(key: 'user_name') ?? user?.displayName ?? 'مواطن';

      // 3. Atomic Batch Write: Add Post + Increment Points
      final batch = _firestore.batch();
      final postDocRef = _firestore.collection('posts').doc();

      final postData = {
        'title': title,
        'imageUrl': imageUrl,
        'location': {
          'lat': lat,
          'long': lng,
        },
        'district': 'معادي',
        'status': 'قيد المراجعه',
        'creatorId': userId,
        'creatorName': userName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(postDocRef, postData);
      batch.update(
        _firestore.collection('users').doc(userId),
        {'points': FieldValue.increment(25)},
      );

      await batch.commit();

      // 4. Fetch authoritative points from Firestore to prevent drift
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final actualPoints = (userDoc.data()?['points'] as num?)?.toInt() ?? 25;

      // 5. Update cached points in secure storage
      await _storage.write(key: 'user_points', value: actualPoints.toString());

      return PostModel(
        id: postDocRef.id,
        imageUrl: imageUrl,
        lat: lat,
        lng: lng,
        creatorId: userId,
        userPoints: actualPoints,
        creatorName: userName,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }
}