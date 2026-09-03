// lib/features/auth/data/repo/auth_repo.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:hai_app/core/services/firebase_auth_service.dart';
import 'package:hai_app/features/auth/data/model/user.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthRepo {
  final FirebaseAuthService _authService;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _storage;

  AuthRepo(this._authService, this._firestore, this._storage);

  Future<bool> isLoggedIn() async {
    return _authService.isLoggedIn;
  }

  Future<User> login(String email, String password) async {
    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const ServerFailure('فشل تسجيل الدخول، يرجى المحاولة مرة أخرى');
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      final User user;
      if (doc.exists && data != null) {
        user = User.fromFirestore(data, uid);
      } else {
        // Auto-provision profile for console-created accounts (e.g., admin or testing)
        final defaultName = (credential.user?.displayName?.isNotEmpty == true)
            ? credential.user!.displayName!
            : email.split('@').first;
        final isAdmin = email.toLowerCase().contains('admin');
        user = User(
          userId: uid,
          isAdmin: isAdmin,
          name: defaultName.isNotEmpty ? defaultName : 'مستخدم',
          nationalId: '00000000000000',
          address: 'القاهرة',
          email: email,
          points: 0,
        );
        await _firestore.collection('users').doc(uid).set({
          ...user.toFirestore(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await _saveSession(user: user);
      return user;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String address,
    required String nationalId,
  }) async {
    try {
      final credential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw const ServerFailure('فشل إنشاء الحساب، يرجى المحاولة مرة أخرى');
      }

      final user = User(
        userId: uid,
        isAdmin: false,
        name: name,
        nationalId: nationalId,
        address: address,
        email: email,
        points: 0,
      );

      final userData = {
        ...user.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(uid).set(userData);
      await _saveSession(user: user);

      return user;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    await _storage.deleteAll();
  }

  // ── PRIVATE HELPER ─────────────────────────────────────────────────────────

  Future<void> _saveSession({required User user}) async {
    await _storage.write(key: 'user_id', value: user.userId);
    await _storage.write(key: 'user_name', value: user.name);
    await _storage.write(key: 'user_email', value: user.email);
    await _storage.write(key: 'user_address', value: user.address);
    await _storage.write(key: 'user_national_id', value: user.nationalId);
    await _storage.write(key: 'user_points', value: user.points.toString());
    await _storage.write(key: 'is_admin', value: user.isAdmin.toString());
  }
}
