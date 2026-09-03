// lib/features/auth/presentation/screens/id_card_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';

import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/auth/presentation/cubits/id_card_cubit/id_card_cubit.dart';
import 'package:hai_app/features/auth/presentation/screens/id_card_detection_screen.dart';
import 'package:hai_app/features/auth/presentation/screens/selfie_screen.dart';
import 'package:hai_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:hai_app/features/auth/presentation/widgets/page_dots.dart';

class IdCardScreen extends StatelessWidget {
  const IdCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppPadding.symmetricPadding(16, 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const PageDots(activeIndex: 1),
                  SizedBox(height: 56.h),
                  Container(
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        children: [
                          AppText.h1('تأكيد الهوية'),
                          SizedBox(height: 12.h),
                          AppText.x1(
                            'يرجى التقاط صوره واضحه للهويه الشخصيه الخاصه بك حيث يظهر بها صورتك الشخصيه والرقم القومي بوضوح',
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            height: 48.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              onPressed: () => _onPickIdCard(context),
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
                                    'رفع البطاقة',
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
                  ),
                ],
              ),
              AuthButton(
                text: 'إلغاء',
                btnColor: AppColors.card,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onPickIdCard(BuildContext context) async {
    // Step 1: Let the user pick the ID card from gallery and verify it has a face.
    final File? confirmedCard = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => GetIt.I<IdCardCubit>(),
          child: const IdCardDetectionScreen(),
        ),
      ),
    );

    if (confirmedCard == null || !context.mounted) return;

    debugPrint('[IdCardScreen] ✅ ID card confirmed: ${confirmedCard.path}');

    // Step 2: Navigate to selfie screen, PASSING the confirmed file.
    // SelfieScreen owns the FaceVerificationCubit and immediately starts
    // extracting the ID face embedding in the background.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelfieScreen(idCardFile: confirmedCard),
      ),
    );
  }
}