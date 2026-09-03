import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/features/auth/data/repo/auth_repo.dart';
import 'package:hai_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:hai_app/features/profile/presentation/cubit/profile_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ProfileCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
          await context.read<ProfileCubit>().loadUserData();
              },
              child: ListView(
                children: [
                  _buildUserDetailsSection(),
                  _buildDarkModeSection(),
                  _buildAccountSection(context),
                  _buildHelpSection(),
                  _buildLogoutSection(context),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildDarkModeSection() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: AppPadding.allPadding(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.h2('الشكل:', color: AppColors.h1, fullWidth: false),
              SizedBox(height: 16.h),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                width: 343.w,
                height: 60.h,
                child: Center(
                  child: Padding(
                    padding: AppPadding.allPadding(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: AppPadding.bottomPadding(5),
                          child: SvgPicture.asset(
                            AppImages.lamp,
                            width: 16.w,
                            height: 16.h,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        AppText.x1(
                          'الوضع الداكن',
                          color: AppColors.h1,
                          fullWidth: false,
                        ),
                        Spacer(),
                        // The Switch Widget connected to Bloc
                        _buildCustomSwitch(context),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomSwitch(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        bool isActive = state.isDarkMode;

        return GestureDetector(
          onTap: () {
            context.read<ProfileCubit>().toggleTheme();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60.0,
            height: 30.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.0),
              color: isActive ? AppColors.primary : AppColors.background,
            ),
            alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: AnimatedAlign(
                alignment: isActive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 24.0,
                  height: 24.0,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 2.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Static Sections (No Logic Change) ---

  Widget _buildUserDetailsSection() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.6),
                AppColors.background,
              ],
              stops: const [0, 0.9],
            ),
          ),
          padding: EdgeInsets.only(top: 32.h, bottom: 28.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3.w),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        AppImages.profilePic,
                        width: 80.r,
                        height: 80.r,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 0,
                    child: GestureDetector(
                      child: Container(
                        width: 26.r,
                        height: 26.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.w,
                          ),
                        ),
                        child: SvgPicture.asset(AppImages.edit),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              AppText.h2(
                state.userName,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText.x2(
                    state.userRank,
                    color: AppColors.x2,
                    fullWidth: false,
                  ),
                  SizedBox(width: 6.w),
                  Container(width: 1.w, height: 12.h, color: AppColors.x2),
                  SizedBox(width: 6.w),
                  AppText.x2(
                    '${state.points}',
                    color: AppColors.primary,
                    fullWidth: false,
                  ),
                  SizedBox(width: 2.w),
                  AppText.x2('نقطة', color: AppColors.x2, fullWidth: false),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountSection(context) {
    return Padding(
      padding: AppPadding.allPadding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h2('الحساب:', color: AppColors.h1, fullWidth: false),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16.0),
            ),
            width: 343.w,
            height: 120.h,
            child: Center(
              child: Padding(
                padding: AppPadding.allPadding(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: Padding(
                        padding: AppPadding.topPadding(7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: AppPadding.bottomPadding(5),
                              child: SvgPicture.asset(
                                AppImages.lang,
                                width: 16.w,
                                height: 16.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            AppText.x1(
                              'اللغه المستخدمه',
                              color: AppColors.h1,
                              fullWidth: false,
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              AppImages.leftArrow,
                              width: 24.w,
                              height: 24.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.pushNamed(context, RouteNames.coupons);
                      },
                      child: Padding(
                        padding: AppPadding.bottomPadding(7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: AppPadding.bottomPadding(5),
                              child: SvgPicture.asset(
                                AppImages.discount,
                                width: 16.w,
                                height: 16.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            AppText.x1(
                              'كوبوناتي',
                              color: AppColors.h1,
                              fullWidth: false,
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              AppImages.leftArrow,
                              width: 24.w,
                              height: 24.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Padding(
      padding: AppPadding.allPadding(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.h2('المساعده والدعم:', color: AppColors.h1, fullWidth: false),
          SizedBox(height: 16.h),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16.0),
            ),

            width: 343.w,
            height: 120.h,
            child: Center(
              child: Padding(
                padding: AppPadding.allPadding(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      child: Padding(
                        padding: AppPadding.topPadding(7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: AppPadding.bottomPadding(5),
                              child: SvgPicture.asset(
                                AppImages.messageQuestion,
                                width: 16.w,
                                height: 16.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            AppText.x1(
                              'الاساله المتكرره',
                              color: AppColors.h1,
                              fullWidth: false,
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              AppImages.leftArrow,
                              width: 24.w,
                              height: 24.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      child: Padding(
                        padding: AppPadding.bottomPadding(7),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: AppPadding.bottomPadding(5),
                              child: SvgPicture.asset(
                                AppImages.message,
                                width: 16.w,
                                height: 16.h,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            AppText.x1(
                              'تواصل مع دعم حي',
                              color: AppColors.h1,
                              fullWidth: false,
                            ),
                            Spacer(),
                            SvgPicture.asset(
                              AppImages.leftArrow,
                              width: 24.w,
                              height: 24.h,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: AppPadding.allPadding(16),
      child: GestureDetector(
        onTap: () async {
          await getIt<AuthRepo>().logout();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.welcomeBoard,
              (route) => false,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16.0),
          ),
          width: 343.w,
          height: 60.h,
          child: Center(
            child: Padding(
              padding: AppPadding.allPadding(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: AppPadding.bottomPadding(5),
                    child: SvgPicture.asset(
                      AppImages.logout,
                      width: 16.w,
                      height: 16.h,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  AppText.x1(
                    'تسجيل الخروج',
                    color: AppColors.h1,
                    fullWidth: false,
                  ),
                  Spacer(),
                  SvgPicture.asset(
                    AppImages.leftArrow,
                    width: 24.w,
                    height: 24.h,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
