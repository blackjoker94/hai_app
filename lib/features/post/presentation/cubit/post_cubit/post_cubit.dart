import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_app/core/network/errors/failure.dart';
import 'package:hai_app/core/services/classification_service.dart';
import 'package:hai_app/core/services/geo_service.dart';
import 'package:hai_app/core/services/image_service.dart';
import 'package:hai_app/features/post/data/repo/post_repo.dart';
import 'package:hai_app/features/post/presentation/cubit/post_cubit/post_state.dart';
import 'package:injectable/injectable.dart';

@injectable
class PostCubit extends Cubit<PostState> {
  final PostRepo _repo;
  final ImageService _imageService;
  final GeoService _geoService;
  final ClassificationService _classifier;

  File? _pickedImage;
  double? _lat;
  double? _lng;

  PostCubit(
    this._repo,
    this._imageService,
    this._geoService,
    this._classifier,
  ) : super(PostInitial());

  Future<void> checkLocationOnEntry() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(PostLocationDisabled(reason: LocationBlockReason.serviceOff));
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      emit(PostLocationDisabled(
          reason: LocationBlockReason.permissionPermanentlyDenied));
      return;
    }
    if (permission == LocationPermission.denied) {
      emit(PostLocationDisabled(reason: LocationBlockReason.permissionDenied));
      return;
    }
    emit(PostInitial());
  }

  Future<void> pickImage({bool fromCamera = false}) async {
    final file = await _imageService.pickImage(
      fromCamera: fromCamera,
      imageQuality: 85,
    );
    if (file == null) return;

    _pickedImage = file;
    _lat = null;
    _lng = null;

    emit(PostClassifying(file));
    final prediction = await _classifier.classify(file);

    if (prediction == null) {
      emit(PostClassificationFailed());
      return;
    }

    emit(PostClassified(image: file, prediction: prediction));
  }

  Future<void> fetchLocation() async {
    final image = _pickedImage;
    final currentState = state;

    final prediction = switch (currentState) {
      PostClassified s => s.prediction,
      PostLocationFetched s => s.prediction,
      _ => null,
    };

    if (image == null || prediction == null) return;

    emit(PostFetchingLocation(image: image, prediction: prediction));

    final position = await _geoService.getCurrentPosition();

    if (position == null) {
      emit(PostError('تعذّر تحديد الموقع. تأكد من تفعيل GPS.'));
      emit(PostClassified(image: image, prediction: prediction));
      return;
    }

    _lat = position.latitude;
    _lng = position.longitude;

    emit(PostLocationFetched(
      image: image,
      prediction: prediction,
      lat: _lat!,
      lng: _lng!,
    ));
  }

  Future<void> submit() async {
    final image = _pickedImage;
    final lat = _lat;
    final lng = _lng;

    final currentState = state;
    final prediction = currentState is PostLocationFetched
        ? currentState.prediction
        : null;

    if (image == null || lat == null || lng == null || prediction == null) {
      emit(PostError('الصورة والموقع مطلوبان'));
      return;
    }

    final reportLabel = prediction.arabicLabel;
    final reportTitle = prediction.label.toLowerCase();

    emit(PostLoading());

    try {
      final post = await _repo.createPost(
        image: image,
        lat: lat,
        lng: lng,
        title: reportTitle,
      );
      emit(PostSuccess(post, reportLabel: reportLabel));
    } catch (e, stack) {
      debugPrint('POST ERROR: $e\nSTACK: $stack');
      if (e is Failure) {
        emit(PostError(e.message));
      } else {
        emit(PostError(e.toString()));
      }
    }
  }

  void reset() {
    _pickedImage = null;
    _lat = null;
    _lng = null;
    emit(PostInitial());
  }
}