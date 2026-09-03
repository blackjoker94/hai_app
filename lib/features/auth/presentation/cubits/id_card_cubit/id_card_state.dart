// lib/features/auth/presentation/cubit/id_card_cubit/id_card_state.dart

part of 'id_card_cubit.dart';

abstract class IdCardState {}

/// Nothing has happened yet — show the instructions placeholder.
class IdCardInitial extends IdCardState {}

/// Gallery is open OR detection is running — show a loading indicator.
class IdCardLoading extends IdCardState {}

/// Face successfully found on the card — show image + bounding box overlay.
class IdCardSuccess extends IdCardState {
  /// The file the user picked — passed to Image.file for rendering.
  final File imageFile;

  /// Bounding box is in IMAGE pixel coordinates.
  /// The screen's CustomPainter scales it to display coordinates.
  final DetectedFace face;

  IdCardSuccess({required this.imageFile, required this.face});
}

/// Something went wrong — show the error message to the user.
class IdCardError extends IdCardState {
  final String message;

  /// Whether this failure is the silent "user cancelled" case.
  /// The screen uses this to avoid showing a SnackBar for cancellations.
  final bool isCancelled;

  IdCardError({required this.message, this.isCancelled = false});
}