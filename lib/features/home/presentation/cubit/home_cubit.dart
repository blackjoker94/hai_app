import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hai_app/core/services/firebase_auth_service.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/features/home/data/models/city_news.dart';
import 'package:hai_app/features/home/data/models/hero_progress.dart';
import 'package:hai_app/features/home/data/models/report_model.dart';
import 'package:hai_app/features/report/data/remote/report_remote.dart';
import 'package:injectable/injectable.dart';
import 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final FlutterSecureStorage _storage;
  final PostsRemoteDataSource _postsDataSource;
  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  HomeCubit(
    this._storage,
    this._postsDataSource,
    this._firestore,
    this._authService,
  ) : super(const HomeState()) {
    loadHomeData();
  }

  Future<void> loadHomeData({bool isRefresh = false}) async {
    if (isRefresh) {
      emit(state.copyWith(isRefreshing: true));
    } else {
      emit(state.copyWith(status: HomeStatus.loading));
    }

    try {
      var userName = await _storage.read(key: 'user_name') ?? 'المستخدم';
      var userAddress = await _storage.read(key: 'user_address') ?? '';
      var pointsStr = await _storage.read(key: 'user_points') ?? '0';
      var points = int.tryParse(pointsStr) ?? 0;

      // Sync latest authoritative profile from Firestore if online
      final uid = _authService.currentUserId;
      if (uid != null) {
        try {
          final userDoc = await _firestore.collection('users').doc(uid).get();
          final data = userDoc.data();
          if (data != null) {
            points = (data['points'] as num?)?.toInt() ?? points;
            userName = data['name'] as String? ?? userName;
            userAddress = data['address'] as String? ?? userAddress;
            await _storage.write(key: 'user_points', value: points.toString());
            await _storage.write(key: 'user_name', value: userName);
            await _storage.write(key: 'user_address', value: userAddress);
          }
        } catch (_) {}
      }

      final heroData = HeroProgress.fromPoints(points);

      List<Report> reportsData = [];
      String? reportsError;
      try {
        final allPosts = await _postsDataSource.fetchUserPosts();
        reportsData = allPosts.take(2).toList();
      } catch (e) {
        reportsError = e.toString();
      }

      final newsData = [
        const CityNews(
          id: '1',
          title: 'تم التحقق من بلاغ (بلاعه مفتوحه)',
          description:
              'تم البلاغ علي (بلاعه مفتوحه) من قبل البطل (اسامه) و تم....',
          imageUrl: AppImages.cityImage,
        ),
        const CityNews(
          id: '2',
          title: 'حملة تشجير في الحي الثامن',
          description:
              'قام ابطال الحي بمساعدة عمال النظافة في تجميل المنطقة...',
          imageUrl: AppImages.cityImage,
        ),
        const CityNews(
          id: '3',
          title: 'تم التحقق من بلاغ (بلاعه مفتوحه)',
          description:
              'تم البلاغ علي (بلاعه مفتوحه) من قبل البطل (اسامه) و تم....',
          imageUrl: AppImages.cityImage,
        ),
      ];

      emit(state.copyWith(
        status: HomeStatus.success,
        hero: heroData,
        reports: reportsData,
        news: newsData,
        userName: userName,
        userAddress: userAddress,
        isRefreshing: false,
        reportsError: reportsError,
      ));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure));
    }
  }

  Future<void> refreshPoints() async {
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        final userDoc = await _firestore.collection('users').doc(uid).get();
        final data = userDoc.data();
        if (data != null) {
          final points = (data['points'] as num?)?.toInt() ?? 0;
          await _storage.write(key: 'user_points', value: points.toString());
          emit(state.copyWith(hero: HeroProgress.fromPoints(points)));
          return;
        }
      }
      final pointsStr = await _storage.read(key: 'user_points') ?? '0';
      final points = int.tryParse(pointsStr) ?? 0;
      emit(state.copyWith(hero: HeroProgress.fromPoints(points)));
    } catch (_) {}
  }
}