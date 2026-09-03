// lib/features/auth/presentation/screens/selfie_screen.dart

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:hai_app/core/helpers/route_names.dart';

import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/auth/presentation/cubits/face_verification_cubit/face_verification_cubit.dart';
import 'package:hai_app/features/auth/presentation/screens/selfie_camera_screen.dart';
import 'package:hai_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:hai_app/features/auth/presentation/widgets/page_dots.dart';

class SelfieScreen extends StatefulWidget {
  /// The confirmed ID card file returned by [IdCardDetectionScreen].
  /// Required — the comparison cannot happen without it.
  final File idCardFile;

  const SelfieScreen({super.key, required this.idCardFile});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  late final FaceVerificationCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = GetIt.I<FaceVerificationCubit>();

    // Extract the ID card embedding now, while the user reads
    // the selfie instructions. By the time they tap "Open Camera"
    // the embedding will likely already be ready.
    _cubit.processIdCard(widget.idCardFile);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  // ── Camera launch ──────────────────────────────────────────────────────────

  Future<void> _openCamera() async {
    // Share the SAME cubit instance with SelfieCameraScreen so live detection
    // states (FaceDetected, Capturing, PhotoCaptured) flow through the cubit
    // we already initialised with the ID embedding.
    final XFile? capturedPhoto = await Navigator.push<XFile>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _cubit,
          child: const SelfieCameraScreen(),
        ),
      ),
    );

    if (!mounted) return;

    if (capturedPhoto != null) {
      // The user confirmed the selfie — run the comparison.
      _cubit.performComparison(capturedPhoto);
    } else {
      // User pressed back without confirming.
      // Reset state so the button re-enables.
      _cubit.onRetake();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<FaceVerificationCubit, FaceVerificationState>(
        listener: _handleStateChange,
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: AppPadding.symmetricPadding(16, 24),
                child: Column(
                  children: [
                    const PageDots(activeIndex: 0),
                    SizedBox(height: 40.h),
                    _buildCard(state),
                    SizedBox(height: 24.h),
                    AuthButton(
                      text: 'إلغاء',
                      btnColor: AppColors.card,
                      onTap: () => Navigator.pop(context),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── BlocListener ───────────────────────────────────────────────────────────

  void _handleStateChange(BuildContext context, FaceVerificationState state) {
    if (state is FaceVerificationMatchSuccess) {
      _showResultDialog(
        context,
        success: true,
        score: state.matchScore,
      );
    }

    if (state is FaceVerificationMatchFailed) {
      _showResultDialog(
        context,
        success: false,
        score: state.matchScore,
      );
    }

    if (state is FaceVerificationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showResultDialog(
    BuildContext context, {
    required bool success,
    required double score,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          success ? '✅ تم التحقق بنجاح' : '❌ فشل التحقق',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: success ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          success
              ? 'تطابق الوجه بنسبة ${score.toStringAsFixed(1)}%.\nيمكنك المتابعة.'
              : 'نسبة التطابق ${score.toStringAsFixed(1)}',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          if (success)
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                // TODO: navigate to the next sign-up step
                Navigator.pushNamed(context, RouteNames.homeRoot);
              },
              child: const Text('متابعة'),
            )
          else ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                _cubit.onRetake(); // reset to Initial so button re-enables
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card widget ────────────────────────────────────────────────────────────

  Widget _buildCard(FaceVerificationState state) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: const Border(
          right: BorderSide(color: Color(0xFFDDDDDD), width: 1),
          bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Column(
          children: [
            AppText.h1('تأكيد الهوية'),
            SizedBox(height: 12.h),
            AppText.x1(
              'يرجي التقاط صوره واضحه لك ويجب ان تكون الصوره :',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBulletPoint('تأكد من وجود إضاءة مناسبة في المكان'),
                _buildBulletPoint('حافظ على ثبات وجهك أثناء عملية الالتقاط'),
                _buildBulletPoint(
                    'أزل الكمامة أو أي غطاء للوجه قبل البدء بالتصوير'),
                _buildBulletPoint(
                    'تجنب الإضاءة الخلفية القوية التي قد تؤثر على جودة الصورة'),
                _buildBulletPoint(
                    'يُرجى إزالة القبعة أو غطاء الرأس أثناء التصوير'),
                _buildBulletPoint(
                    'يُمنع ارتداء النظارات الشمسية أو النظارات الداكنة أثناء التحقق'),
              ],
            ),

            SizedBox(height: 40.h),

            // ── Status indicator (shown while ID is processing) ─────────────
            if (state is FaceVerificationIdProcessing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  AppText.x3('جاري تحليل صورة البطاقة...', fullWidth: false),
                ],
              ),
              SizedBox(height: 16.h),
            ],

            if (state is FaceVerificationComparing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8.w),
                  AppText.x3('جاري مقارنة الوجوه...'),
                ],
              ),
              SizedBox(height: 16.h),
            ],

            // ── Camera button ───────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCameraEnabled(state)
                      ? AppColors.primary
                      : Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: _isCameraEnabled(state) ? _openCamera : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppImages.camera,
                      width: 20.w,
                      height: 20.h,
                    ),
                    SizedBox(width: 8.w),
                    AppText.x1(
                      _buttonLabel(state),
                      color: AppColors.white,
                      fullWidth: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// The camera button is enabled only when the ID embedding is ready and
  /// the cubit is not in the middle of a comparison.
  bool _isCameraEnabled(FaceVerificationState state) =>
      state is FaceVerificationIdReady ||
      state is FaceVerificationInitial ||
      state is FaceVerificationFaceDetected ||
      state is FaceVerificationMatchFailed ||
      state is FaceVerificationError;

  String _buttonLabel(FaceVerificationState state) {
    if (state is FaceVerificationIdProcessing) return 'جاري التحليل...';
    if (state is FaceVerificationComparing) return 'جاري المقارنة...';
    return 'افتح الكاميرا';
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.x3,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AppText.x3(text, color: AppColors.x3, fullWidth: false),
          ),
        ],
      ),
    );
  }
}