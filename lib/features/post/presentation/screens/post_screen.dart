// lib/features/post/presentation/screens/post_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/post/data/models/prediction_result.dart';
import 'package:hai_app/features/post/presentation/cubit/post_cubit/post_cubit.dart';
import 'package:hai_app/features/post/presentation/cubit/post_cubit/post_state.dart';

class PostScreen extends StatelessWidget {
  const PostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PostCubit>()..checkLocationOnEntry(),
      child: const _PostView(),
    );
  }
}

class _PostView extends StatelessWidget {
  const _PostView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppText.h2('بلّغ عن مشكلة', fullWidth: false),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: BlocConsumer<PostCubit, PostState>(
        listener: (context, state) {
          // ✅ Success → navigate to chat, pop post screen
          if (state is PostSuccess) {
            Navigator.pop(context);
            Navigator.pushNamed(context, RouteNames.chat,arguments: {'reportLabel': state.reportLabel},);
          }

          // ✅ Classification failed (< 50%) → snackbar + stay on screen
          if (state is PostClassificationFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('لم يتم التعرف علي المشكلة يرجي المحاولة'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // ✅ Generic errors (network, location, etc.)
          if (state is PostError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // ✅ GPS/permission gate dialog
          if (state is PostLocationDisabled) {
            _showLocationDialog(context, state.reason);
          }
        },
        builder: (context, state) {
          if (state is PostLocationDisabled) {
            return const SizedBox.shrink();
          }

          final cubit = context.read<PostCubit>();
          final isSubmitting = state is PostLoading;
          final isClassifying = state is PostClassifying;

          // ── Extract image from any state that carries it ──────────────────
          final File? imageFile = switch (state) {
            PostClassifying s => s.image,
            PostClassified s => s.image,
            PostFetchingLocation s => s.image,
            PostLocationFetched s => s.image,
            _ => null,
          };

          // ── Extract prediction if classification passed ───────────────────
          final PredictionResult? prediction = switch (state) {
            PostClassified s => s.prediction,
            PostFetchingLocation s => s.prediction,
            PostLocationFetched s => s.prediction,
            _ => null,
          };

          final isFetchingLocation = state is PostFetchingLocation;
          final locationFetched =
              state is PostLocationFetched ? state : null;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Image Preview Area ───────────────────────────────────
                GestureDetector(
                  onTap: (isSubmitting || isClassifying)
                      ? null
                      : () => _showImageSourceSheet(context, cubit),
                  child: Container(
                    height: 240.h,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: AppColors.x3, width: 1.5),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image or placeholder
                        imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14.r),
                                child: Image.file(
                                  imageFile,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 52.sp,
                                    color: AppColors.primary,
                                  ),
                                  SizedBox(height: 10.h),
                                  AppText.x2(
                                    'اضغط لاختيار صورة',
                                    color: AppColors.x3,
                                    fullWidth: false,
                                  ),
                                ],
                              ),

                        // Classification spinner overlay
                        if (isClassifying)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                SizedBox(height: 12.h),
                                AppText.x2(
                                  'جارٍ تحليل الصورة...',
                                  color: Colors.white,
                                  fullWidth: false,
                                ),
                              ],
                            ),
                          ),

                        // Classification result badge (top-left)
                        if (prediction != null)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${prediction.arabicLabel} · ${prediction.confidencePercent}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // ─── Pick Buttons ─────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.photo_library_outlined,
                        label: 'المعرض',
                        onTap: (isSubmitting || isClassifying)
                            ? null
                            : () => cubit.pickImage(fromCamera: false),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'الكاميرا',
                        onTap: (isSubmitting || isClassifying)
                            ? null
                            : () => cubit.pickImage(fromCamera: true),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16.h),

                // ─── Location Button (shown only after classification passes)
                if (prediction != null)
                  SizedBox(
                    height: 50.h,
                    child: OutlinedButton.icon(
                      onPressed: (isSubmitting || isFetchingLocation)
                          ? null
                          : cubit.fetchLocation,
                      icon: isFetchingLocation
                          ? SizedBox(
                              width: 18.w,
                              height: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              locationFetched != null
                                  ? Icons.location_on
                                  : Icons.my_location,
                              color: AppColors.primary,
                            ),
                      label: Text(
                        isFetchingLocation
                            ? 'جارٍ تحديد الموقع...'
                            : locationFetched != null
                                ? '${locationFetched.lat.toStringAsFixed(4)}, ${locationFetched.lng.toStringAsFixed(4)}'
                                : 'تحديد موقعي الحالي',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: locationFetched != null
                              ? AppColors.primary
                              : AppColors.x3,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),

                SizedBox(height: 28.h),

                // ─── Submit Button (only active when location is ready) ────
                SizedBox(
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: (isSubmitting || locationFetched == null)
                        ? null
                        : cubit.submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.x3.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : AppText.h2(
                            'إرسال البلاغ',
                            color: Colors.white,
                            fullWidth: false,
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLocationDialog(BuildContext context, LocationBlockReason reason) {
    final isPermanent =
        reason == LocationBlockReason.permissionPermanentlyDenied;
    final isServiceOff = reason == LocationBlockReason.serviceOff;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red),
            SizedBox(width: 8.w),
            const Text('الموقع مطلوب'),
          ],
        ),
        content: Text(
          isServiceOff
              ? 'يرجى تفعيل خدمة GPS من إعدادات الجهاز للمتابعة.'
              : isPermanent
                  ? 'تم رفض الإذن بشكل دائم. يرجى تفعيله من إعدادات التطبيق.'
                  : 'هذه الشاشة تحتاج إلى إذن الموقع للمتابعة.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('رجوع', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              if (isServiceOff) {
                await Geolocator.openLocationSettings();
              } else {
                await Geolocator.openAppSettings();
              }
              if (context.mounted) {
                context.read<PostCubit>().checkLocationOnEntry();
              }
            },
            child: Text(
              isServiceOff ? 'فتح الإعدادات' : 'فتح إعدادات التطبيق',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, PostCubit cubit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('اختر من المعرض'),
              onTap: () {
                Navigator.pop(context);
                cubit.pickImage(fromCamera: false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('التقط صورة'),
              onTap: () {
                Navigator.pop(context);
                cubit.pickImage(fromCamera: true);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton(
      {required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(label, style: const TextStyle(color: AppColors.primary)),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}