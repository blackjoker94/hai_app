// lib/features/auth/presentation/screens/id_card_detection_screen.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/services/face_detection_models.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/features/auth/presentation/cubits/id_card_cubit/id_card_cubit.dart';
import 'package:hai_app/features/auth/presentation/widgets/auth_button.dart';

class IdCardDetectionScreen extends StatefulWidget {
  const IdCardDetectionScreen({super.key});

  @override
  State<IdCardDetectionScreen> createState() => _IdCardDetectionScreenState();
}

class _IdCardDetectionScreenState extends State<IdCardDetectionScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-open the gallery immediately when the screen mounts —
    // so the user doesn't have to tap a button twice.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IdCardCubit>().pickAndDetect();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppPadding.symmetricPadding(16, 24),
          child: BlocConsumer<IdCardCubit, IdCardState>(
            listener: (context, state) {
              if (state is IdCardError && !state.isCancelled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              // If user cancelled the picker (state goes back to Initial),
              // pop this screen — they don't want to be here anymore.
              if (state is IdCardInitial) {
                Navigator.pop(context);
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  // ── Header ────────────────────────────────────────────────
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: AppText.h1(
                          'التحقق من البطاقة',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // Balance the back button so the title stays centered
                      SizedBox(width: 48.w),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // ── Image area ────────────────────────────────────────────
                  Expanded(child: _buildImageArea(state)),

                  SizedBox(height: 24.h),

                  // ── Action buttons ────────────────────────────────────────
                  _buildActions(context, state),

                  SizedBox(height: 20.h),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Image area ─────────────────────────────────────────────────────────────

  Widget _buildImageArea(IdCardState state) {
    if (state is IdCardLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            AppText.x1('جاري تحليل البطاقة...'),
          ],
        ),
      );
    }

    if (state is IdCardSuccess) {
      return _buildImageWithOverlay(state);
    }

    if (state is IdCardError) {
      return _buildErrorPlaceholder(state.message);
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 80.sp, color: Colors.grey.shade400),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: AppText.x1(
              'اضغط على "رفع البطاقة" لاختيار صورة بطاقتك',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: Colors.redAccent),
          SizedBox(height: 16.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the picked image with a green bounding box drawn over the
  /// detected face. Uses a FutureBuilder to decode the image's real
  /// pixel dimensions for accurate coordinate scaling.
  Widget _buildImageWithOverlay(IdCardSuccess state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<ui.Image>(
            future: _decodeImage(state.imageFile),
            builder: (context, snapshot) {
              // Show the image immediately while we decode dimensions.
              // The bounding box overlay appears once dimensions are ready.
              return Stack(
                alignment: Alignment.center,
                children: [
                  Image.file(
                    state.imageFile,
                    fit: BoxFit.contain,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                  ),
                  if (snapshot.hasData)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FaceBoundingBoxPainter(
                          face: state.face,
                          imageWidth: snapshot.data!.width.toDouble(),
                          imageHeight: snapshot.data!.height.toDouble(),
                          displayWidth: constraints.maxWidth,
                          displayHeight: constraints.maxHeight,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<ui.Image> _decodeImage(File file) async {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  // ── Buttons ────────────────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context, IdCardState state) {
    final cubit = context.read<IdCardCubit>();

    if (state is IdCardSuccess) {
      return Column(
        children: [
          AuthButton(
            text: 'تأكيد البطاقة',
            btnColor: AppColors.primary,
            onTap: () => Navigator.pop(context, state.imageFile),
          ),
          SizedBox(height: 12.h),
          AuthButton(
            text: 'اختيار صورة أخرى',
            btnColor: AppColors.card,
            onTap: () => cubit.pickAndDetect(),
          ),
        ],
      );
    }

    if (state is IdCardError) {
      return Column(
        children: [
          AuthButton(
            text: 'حاول مرة أخرى',
            btnColor: AppColors.primary,
            onTap: () => cubit.pickAndDetect(),
          ),
          SizedBox(height: 12.h),
          AuthButton(
            text: 'إلغاء',
            btnColor: AppColors.card,
            onTap: () => Navigator.pop(context),
          ),
        ],
      );
    }

    // Loading state — disabled button
    return AuthButton(
      text: 'جاري التحميل...',
      btnColor: AppColors.card,
      onTap: null,
    );
  }
}

// ── CustomPainter ──────────────────────────────────────────────────────────────

/// Draws a rounded bounding box around the detected face on the ID card.
///
/// WHY the math here matters:
///   ML Kit returns coordinates in IMAGE pixel space (e.g. x=120 in a 1200px image).
///   Image.file with BoxFit.contain letterboxes/pillarboxes the image inside
///   the display rect. We compute the same scale + offset the Flutter renderer
///   uses, then transform the bounding box into display coordinates.
class FaceBoundingBoxPainter extends CustomPainter {
  final DetectedFace face;
  final double imageWidth;
  final double imageHeight;
  final double displayWidth;
  final double displayHeight;

  const FaceBoundingBoxPainter({
    required this.face,
    required this.imageWidth,
    required this.imageHeight,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ── 1. Compute BoxFit.contain scale and letterbox offset ───────────────
    final double scaleX = displayWidth  / imageWidth;
    final double scaleY = displayHeight / imageHeight;
    // contain = smallest scale so the whole image fits inside the display rect
    final double scale  = scaleX < scaleY ? scaleX : scaleY;

    final double renderedW = imageWidth  * scale;
    final double renderedH = imageHeight * scale;

    // Letterbox / pillarbox gap from the top-left of the display area
    final double offsetX = (displayWidth  - renderedW) / 2;
    final double offsetY = (displayHeight - renderedH) / 2;

    // ── 2. Transform bounding box from image → display coordinates ─────────
    final Rect imageBbox   = face.boundingBox;
    final Rect displayBbox = Rect.fromLTRB(
      offsetX + imageBbox.left   * scale,
      offsetY + imageBbox.top    * scale,
      offsetX + imageBbox.right  * scale,
      offsetY + imageBbox.bottom * scale,
    );

    // ── 3. Semi-transparent green fill ────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(displayBbox, const Radius.circular(8)),
      Paint()
        ..color = Colors.greenAccent.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );

    // ── 4. Green border ───────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(displayBbox, const Radius.circular(8)),
      Paint()
        ..color = Colors.greenAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // ── 5. Landmark dots ─────────────────────────────────────────────────
    final Paint dotPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.fill;

    for (final offset in face.landmarks.values) {
      canvas.drawCircle(
        Offset(
          offsetX + offset.dx * scale,
          offsetY + offset.dy * scale,
        ),
        3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(FaceBoundingBoxPainter old) =>
      old.face          != face          ||
      old.displayWidth  != displayWidth  ||
      old.displayHeight != displayHeight;
}