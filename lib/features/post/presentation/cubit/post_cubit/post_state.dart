import 'dart:io';
import 'package:hai_app/features/post/data/models/post_model.dart';
import 'package:hai_app/features/post/data/models/prediction_result.dart';

enum LocationBlockReason {
  serviceOff,
  permissionDenied,
  permissionPermanentlyDenied,
}

abstract class PostState {}

class PostInitial extends PostState {}

class PostLocationDisabled extends PostState {
  final LocationBlockReason reason;
  PostLocationDisabled({required this.reason});
}

class PostClassifying extends PostState {
  final File image;
  PostClassifying(this.image);
}

class PostClassified extends PostState {
  final File image;
  final PredictionResult prediction;
  PostClassified({required this.image, required this.prediction});
}

class PostClassificationFailed extends PostState {}

class PostFetchingLocation extends PostState {
  final File image;
  final PredictionResult prediction;
  PostFetchingLocation({required this.image, required this.prediction});
}

class PostLocationFetched extends PostState {
  final File image;
  final PredictionResult prediction;
  final double lat;
  final double lng;

  PostLocationFetched({
    required this.image,
    required this.prediction,
    required this.lat,
    required this.lng,
  });
}

class PostLoading extends PostState {}

class PostSuccess extends PostState {
  final PostModel post;
  final String reportLabel;
  PostSuccess(this.post, {required this.reportLabel});
}

class PostError extends PostState {
  final String message;
  PostError(this.message);
}