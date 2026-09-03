// lib/features/home/presentation/home_screen.dart

import 'package:easy_stepper/easy_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';
import 'package:hai_app/features/home/data/models/city_news.dart';
import 'package:hai_app/features/home/data/models/hero_progress.dart';
import 'package:hai_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:hai_app/features/home/presentation/cubit/home_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<HomeCubit>(),
      child: Scaffold(
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.status == HomeStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state.status == HomeStatus.failure) {
              return Center(
                child: Text('حدث خطأ ما', style: AppTextStyles.h2()),
              );
            }
            if (state.status == HomeStatus.success && state.hero != null) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<HomeCubit>().loadHomeData(isRefresh: true);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: ListView(
                  children: [
                    _buildHeaderSection(context, state),
                    _buildHeroProgressSection(state.hero!),
                    _buildReportsSection(context, state),
                    _buildCityNewsSection(state.news),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            child: const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage(AppImages.profilePic),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.h2(
                  "مرحبا, ${state.userName}",
                  color: AppColors.h1,
                  fullWidth: false,
                ),
                AppText.x2(
                  state.userAddress,
                  color: AppColors.primary,
                  fullWidth: false,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, RouteNames.notifications);
            },
            child: Container(
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                    color: Colors.black.withOpacity(0.05), width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child:
                  SvgPicture.asset(AppImages.notifications, fit: BoxFit.scaleDown),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProgressSection(HeroProgress hero) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.background.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary.withOpacity(0.4), AppColors.card],
            stops: const [0, 0.5],
          ),
        ),
        padding: AppPadding.symmetricPadding(12, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "لديك ",
                              style: AppTextStyles.h1(color: Colors.black),
                            ),
                            TextSpan(
                              text: "${hero.points}",
                              style:
                                  AppTextStyles.h1(color: AppColors.primary),
                            ),
                            TextSpan(
                              text: " نقطة",
                              style: AppTextStyles.h1(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AppText.x1(
                        "الحالة الحالية: ${hero.currentRank}",
                        color: AppColors.primary,
                        fullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: AppPadding.verticalPadding(4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AppText.x1(
                            "أنت على بعد ${hero.pointsToNextRank} \nنقطة لتصبح ${hero.nextRank}",
                            color: AppColors.primary,
                            fullWidth: false,
                            textAlign: TextAlign.end,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Image.asset(AppImages.crown),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            _buildHeroProgressStepper(hero.activeStepIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroProgressStepper(int activeStep) {
    return EasyStepper(
      activeStep: activeStep,
      showLoadingAnimation: false,
      steps: [
        EasyStep(
          customStep: _glowIcon(
            child: SvgPicture.asset(
              activeStep >= 0 ? AppImages.reachedLeaf : AppImages.hero,
              width: 30.w,
              height: 30.h,
            ),
            isReached: activeStep >= 0,
            isCurrent: activeStep == 0,
          ),
          customTitle: AppText.x2(
            'مبتدئ',
            color: activeStep >= 0 ? AppColors.primary : AppColors.x3,
            fullWidth: false,
          ),
        ),
        EasyStep(
          customStep: _glowIcon(
            child: SvgPicture.asset(
              AppImages.star,
              width: 30.w,
              height: 30.h,
              color: activeStep >= 1 ? AppColors.primary : AppColors.x3,
            ),
            isReached: activeStep >= 1,
            isCurrent: activeStep == 1,
          ),
          customTitle: AppText.x2(
            'مساعد',
            color: activeStep >= 1 ? AppColors.primary : AppColors.x3,
            fullWidth: false,
          ),
        ),
        EasyStep(
          customStep: _glowIcon(
            child: SvgPicture.asset(
              activeStep >= 2 ? AppImages.reachedHero : AppImages.hero,
              width: 30.w,
              height: 30.h,
            ),
            isReached: activeStep >= 2,
            isCurrent: activeStep == 2,
          ),
          customTitle: AppText.x2(
            'بطل',
            color: activeStep >= 2 ? AppColors.primary : AppColors.x3,
            fullWidth: false,
          ),
        ),
        EasyStep(
          customStep: _glowIcon(
            child: SvgPicture.asset(
              activeStep >= 3 ? AppImages.reachedHero : AppImages.hero,
              width: 30.w,
              height: 30.h,
            ),
            isReached: activeStep >= 3,
            isCurrent: activeStep == 3,
          ),
          customTitle: AppText.x2(
            'الكبير',
            color: activeStep >= 3 ? AppColors.primary : AppColors.x3,
            fullWidth: false,
          ),
        ),
      ],
      lineStyle: const LineStyle(
        lineType: LineType.normal,
        unreachedLineType: LineType.normal,
        lineLength: 50,
        lineThickness: 2,
        defaultLineColor: AppColors.x3,
        activeLineColor: AppColors.x3,
        finishedLineColor: AppColors.primary,
      ),
      enableStepTapping: false,
      onStepReached: null,
      showTitle: true,
      showStepBorder: false,
      stepShape: StepShape.rRectangle,
      stepRadius: 20,
      activeStepIconColor: AppColors.primary,
      activeStepTextColor: AppColors.primary,
      finishedStepTextColor: AppColors.primary,
      finishedStepBackgroundColor: Colors.transparent,
      unreachedStepIconColor: Colors.transparent,
      stepAnimationCurve: Curves.easeInOut,
      stepAnimationDuration: const Duration(milliseconds: 300),
      alignment: Alignment.center,
    );
  }

  Widget _glowIcon({
    required Widget child,
    required bool isReached,
    required bool isCurrent,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: 36.w,
      height: 36.h,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: Center(child: child),
    );
  }


  Widget _buildReportsSection(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pushNamed(context, RouteNames.myReports),
            child: SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  AppText.h2('بلاغاتك:', color: AppColors.h1, fullWidth: false),
                  const Spacer(),
                  SvgPicture.asset(AppImages.leftArrow,
                      width: 24.w, height: 24.h),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          if (state.reportsError != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.red.withOpacity(0.2), width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.wifi_off_rounded,
                      color: Colors.red.withOpacity(0.6), size: 32.r),
                  SizedBox(height: 8.h),
                  AppText.x2('تعذّر تحميل البلاغات',
                      color: AppColors.x3, fullWidth: false),
                  SizedBox(height: 8.h),
                  GestureDetector(
                    onTap: () =>
                        context.read<HomeCubit>().loadHomeData(isRefresh: true),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText.x2('إعادة المحاولة',
                          color: Colors.white, fullWidth: false),
                    ),
                  ),
                ],
              ),
            ),
          ]

          else if (state.reports.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppText.x2('لا توجد بلاغات حتى الآن',
                    color: AppColors.x3, fullWidth: false),
              ),
            ),
          ]

          else ...[
            ...state.reports.map(
              (report) => _buildReportCard(
                title: report.title,
                subtitle: report.status,
                description: report.ticketNumber,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required String description,
  }) {
    return GestureDetector(
      child: Padding(
        padding: AppPadding.bottomPadding(16),
        child: Container(
          width: 343.w,
          height: 80.h,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.background.withOpacity(0.05),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: AppPadding.symmetricPadding(12, 17),
                child: SvgPicture.asset(
                  AppImages.report,
                  width: 20,
                  height: 45,
                  color: Colors.black,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.x1(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppText.x3(subtitle, color: AppColors.x3, fullWidth: false),
                    AppText.x3(description,
                        color: AppColors.primary, fullWidth: false),
                  ],
                ),
              ),
              SvgPicture.asset(AppImages.leftArrow),
              SizedBox(width: 12.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityNewsSection(List<CityNews> newsList) {
    if (newsList.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppText.h2('اخبار المدينه:',
                  color: AppColors.h1, fullWidth: false),
              const Spacer(),
              SvgPicture.asset(AppImages.leftArrow, width: 24.w, height: 24.h),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 175.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: newsList.length,
              itemBuilder: (context, index) {
                final news = newsList[index];
                return _buildCityNewsCard(
                  title: news.title,
                  description: news.description,
                  imageUrl: news.imageUrl,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityNewsCard({
    required String title,
    required String description,
    required String imageUrl,
  }) {
    return GestureDetector(
      child: Container(
        width: 250.w,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.background.withOpacity(0.05),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              child: Image.asset(
                imageUrl,
                width: 108.w,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Padding(
                padding: AppPadding.verticalPadding(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    AppText.x1(title, fullWidth: false),
                    SizedBox(height: 4.h),
                    Expanded(
                      child: Text(
                        description,
                        style: AppTextStyles.x2(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 104.w,
                      height: 25.h,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.background.withOpacity(0.05),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AppText.x1(
                          'قراءه المزيد',
                          color: AppColors.primary,
                          fullWidth: false,
                        ),
                      ),
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
}