// lib/features/auth/presentation/cubit/id_card_cubit/id_card_cubit.dart

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:hai_app/core/services/face_detection_models.dart';
import 'package:hai_app/features/auth/data/repo/id_card_repository.dart';

part 'id_card_state.dart';

@injectable
class IdCardCubit extends Cubit<IdCardState> {
  final IdCardRepository _repository;

  IdCardCubit(this._repository) : super(IdCardInitial());

  /// Opens the gallery and runs detection. Handles all outcomes via state.
  Future<void> pickAndDetect() async {
    emit(IdCardLoading());

    final (failure, result) = await _repository.pickAndDetect();

    // Guard: cubit may have been closed while awaiting the gallery picker
    // (e.g. user navigated away mid-pick).
    if (isClosed) return;

    if (failure != null) {
      debugPrint('[IdCardCubit] ❌ ${failure.type.name}: ${failure.message}');

      // Cancelled is a silent non-error — go back to initial so the
      // instructions placeholder is shown again, not a red error card.
      if (failure.type == IdCardFailureType.cancelled) {
        emit(IdCardInitial());
        return;
      }

      emit(IdCardError(message: failure.message));
      return;
    }

    debugPrint(
      '[IdCardCubit] ✅ ID card face detected → '
      'bbox: ${result!.face.boundingBox}, '
      'landmarks: ${result.face.landmarks.length}, '
      'file: ${result.imageFile.path}',
    );

    emit(IdCardSuccess(imageFile: result.imageFile, face: result.face));
  }

  /// Called when the user taps "اختيار صورة أخرى" — resets to initial
  /// so the placeholder and upload button are shown again.
  void reset() {
    debugPrint('[IdCardCubit] 🔄 Reset');
    emit(IdCardInitial());
  }
}