import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hai_app/core/services/firebase_auth_service.dart';
import 'package:hai_app/features/home/data/models/hero_progress.dart';
import 'package:injectable/injectable.dart';
import 'profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  final FlutterSecureStorage _storage;
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  ProfileCubit(
    this._storage,
    this._firestore,
    this._authService,
  ) : super(const ProfileState()) {
    loadUserData();
  }

  void toggleTheme() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  Future<void> loadUserData() async {
    var userName = await _storage.read(key: 'user_name') ?? 'المستخدم';
    var pointsStr = await _storage.read(key: 'user_points') ?? '0';
    var points = int.tryParse(pointsStr) ?? 0;

    final uid = _authService.currentUserId;
    if (uid != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final data = userDoc.data();
        if (data != null) {
          points = (data['points'] as num?)?.toInt() ?? points;
          userName = data['name'] as String? ?? userName;
          await _storage.write(key: 'user_points', value: points.toString());
          await _storage.write(key: 'user_name', value: userName);
        }
      } catch (_) {}
    }

    final hero = HeroProgress.fromPoints(points);

    emit(state.copyWith(
      userName: userName,
      userRank: hero.currentRank,
      points: points,
    ));
  }
}