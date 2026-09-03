// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hai_app/core/di/firebase_module.dart' as _i789;
import 'package:hai_app/core/di/storage_module.dart' as _i745;
import 'package:hai_app/core/network/networkservice.dart' as _i96;
import 'package:hai_app/core/services/camera_service.dart' as _i611;
import 'package:hai_app/core/services/classification_service.dart' as _i600;
import 'package:hai_app/core/services/cloudinary_service.dart' as _i325;
import 'package:hai_app/core/services/connectivity_service.dart' as _i177;
import 'package:hai_app/core/services/face_comparison_service.dart' as _i242;
import 'package:hai_app/core/services/face_detection_service.dart' as _i853;
import 'package:hai_app/core/services/file_service.dart' as _i16;
import 'package:hai_app/core/services/firebase_auth_service.dart' as _i282;
import 'package:hai_app/core/services/geo_service.dart' as _i941;
import 'package:hai_app/core/services/image_service.dart' as _i24;
import 'package:hai_app/core/services/notification_service.dart' as _i7;
import 'package:hai_app/features/auth/data/repo/auth_repo.dart' as _i496;
import 'package:hai_app/features/auth/data/repo/face_verification_repository.dart'
    as _i507;
import 'package:hai_app/features/auth/data/repo/id_card_repository.dart'
    as _i446;
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_cubit.dart'
    as _i1036;
import 'package:hai_app/features/auth/presentation/cubits/face_verification_cubit/face_verification_cubit.dart'
    as _i339;
import 'package:hai_app/features/auth/presentation/cubits/id_card_cubit/id_card_cubit.dart'
    as _i330;
import 'package:hai_app/features/home/presentation/cubit/home_cubit.dart'
    as _i192;
import 'package:hai_app/features/post/data/repo/post_repo.dart' as _i643;
import 'package:hai_app/features/post/presentation/cubit/post_cubit/post_cubit.dart'
    as _i394;
import 'package:hai_app/features/profile/presentation/cubit/profile_cubit.dart'
    as _i499;
import 'package:hai_app/features/report/data/remote/report_remote.dart'
    as _i1062;
import 'package:hai_app/features/report/presentation/cubit/report_cubit.dart'
    as _i594;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    final storageModule = _$StorageModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => firebaseModule.firestore);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => storageModule.secureStorage,
    );
    gh.lazySingleton<_i96.NetworkService>(() => _i96.NetworkService());
    gh.lazySingleton<_i611.CameraService>(() => _i611.CameraService());
    gh.lazySingleton<_i600.ClassificationService>(
      () => _i600.ClassificationService(),
    );
    gh.lazySingleton<_i177.ConnectivityService>(
      () => _i177.ConnectivityService(),
    );
    gh.lazySingleton<_i242.FaceComparisonService>(
      () => _i242.FaceComparisonService(),
    );
    gh.lazySingleton<_i853.FaceDetectionService>(
      () => _i853.FaceDetectionService(),
    );
    gh.lazySingleton<_i16.FileService>(() => _i16.FileService());
    gh.lazySingleton<_i941.GeoService>(() => _i941.GeoService());
    gh.lazySingleton<_i24.ImageService>(() => _i24.ImageService());
    gh.lazySingleton<_i7.LocalNotificationService>(
      () => _i7.LocalNotificationService(),
    );
    gh.lazySingleton<_i325.CloudinaryService>(
      () => _i325.CloudinaryService(gh<_i96.NetworkService>()),
    );
    gh.lazySingleton<_i446.IdCardRepository>(
      () => _i446.IdCardRepositoryImpl(
        gh<_i24.ImageService>(),
        gh<_i853.FaceDetectionService>(),
      ),
    );
    gh.lazySingleton<_i507.FaceVerificationRepository>(
      () => _i507.FaceVerificationRepositoryImpl(
        gh<_i853.FaceDetectionService>(),
        gh<_i242.FaceComparisonService>(),
        gh<_i611.CameraService>(),
      ),
    );
    gh.factory<_i339.FaceVerificationCubit>(
      () => _i339.FaceVerificationCubit(gh<_i507.FaceVerificationRepository>()),
    );
    gh.lazySingleton<_i282.FirebaseAuthService>(
      () => _i282.FirebaseAuthService(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i643.PostRepo>(
      () => _i643.PostRepo(
        gh<_i974.FirebaseFirestore>(),
        gh<_i282.FirebaseAuthService>(),
        gh<_i558.FlutterSecureStorage>(),
        gh<_i325.CloudinaryService>(),
      ),
    );
    gh.factory<_i499.ProfileCubit>(
      () => _i499.ProfileCubit(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i282.FirebaseAuthService>(),
      ),
    );
    gh.factory<_i1062.PostsRemoteDataSource>(
      () => _i1062.PostsRemoteDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i282.FirebaseAuthService>(),
      ),
    );
    gh.factory<_i394.PostCubit>(
      () => _i394.PostCubit(
        gh<_i643.PostRepo>(),
        gh<_i24.ImageService>(),
        gh<_i941.GeoService>(),
        gh<_i600.ClassificationService>(),
      ),
    );
    gh.factory<_i330.IdCardCubit>(
      () => _i330.IdCardCubit(gh<_i446.IdCardRepository>()),
    );
    gh.lazySingleton<_i496.AuthRepo>(
      () => _i496.AuthRepo(
        gh<_i282.FirebaseAuthService>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i558.FlutterSecureStorage>(),
      ),
    );
    gh.factory<_i192.HomeCubit>(
      () => _i192.HomeCubit(
        gh<_i558.FlutterSecureStorage>(),
        gh<_i1062.PostsRemoteDataSource>(),
        gh<_i974.FirebaseFirestore>(),
        gh<_i282.FirebaseAuthService>(),
      ),
    );
    gh.factory<_i594.ReportsCubit>(
      () => _i594.ReportsCubit(gh<_i1062.PostsRemoteDataSource>()),
    );
    gh.factory<_i1036.AuthCubit>(() => _i1036.AuthCubit(gh<_i496.AuthRepo>()));
    return this;
  }
}

class _$FirebaseModule extends _i789.FirebaseModule {}

class _$StorageModule extends _i745.StorageModule {}
