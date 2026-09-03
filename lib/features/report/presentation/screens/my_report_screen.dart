// lib/features/home/presentation/my_reports/my_reports_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';
import 'package:hai_app/features/home/data/models/report_model.dart';
import 'package:hai_app/features/report/presentation/cubit/report_cubit.dart';
import 'package:hai_app/features/report/presentation/cubit/report_state.dart';


class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>(),
      child: const _MyReportsView(),
    );
  }
}

class _MyReportsView extends StatelessWidget {
  const _MyReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: AppColors.card,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: SvgPicture.asset(AppImages.rightArrow, color: AppColors.h1),
          ),
        ),
        title: AppText.h1('بلاغاتك', fullWidth: false),
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          if (state.status == ReportsStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state.status == ReportsStatus.failure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText.h2('حدث خطأ أثناء التحميل', color: AppColors.h1),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () => context.read<ReportsCubit>().loadReports(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary),
                    child: const Text('إعادة المحاولة',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              SizedBox(height: 16.h),
              _buildFilterTabs(context, state.selectedFilterIndex),
              SizedBox(height: 24.h),
              Expanded(child: _buildReportsList(context, state)),
            ],
          );
        },
      ),
    );
  }

  // ── Filter tabs ─────────────────────────────────────────────────────────────

  Widget _buildFilterTabs(BuildContext context, int selectedIndex) {
    return Padding(
      padding: AppPadding.horizontalPadding(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterButton(context, 'الكل', 0, selectedIndex),
          SizedBox(width: 12.w),
          _filterButton(context, 'الحالي', 1, selectedIndex),
          SizedBox(width: 12.w),
          _filterButton(context, 'مكتمل', 2, selectedIndex),
        ],
      ),
    );
  }

  Widget _filterButton(
      BuildContext context, String label, int index, int selected) {
    final bool isSelected = selected == index;
    return GestureDetector(
      onTap: () => context.read<ReportsCubit>().setFilter(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: AppTextStyles.x2().copyWith(
            color: isSelected ? Colors.white : AppColors.x3,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── Reports list ─────────────────────────────────────────────────────────────

  Widget _buildReportsList(BuildContext context, ReportsState state) {
    final reports = state.filteredReports;

    if (reports.isEmpty) {
      return Center(
        child: AppText.h2('لا توجد بلاغات', color: AppColors.x3),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<ReportsCubit>().loadReports(),
      child: ListView.builder(
        padding: AppPadding.allPadding(16),
        itemCount: reports.length,
        itemBuilder: (_, index) => _buildReportCard(reports[index]),
      ),
    );
  }

  // ── Single card ───────────────────────────────────────────────────────────────

  Widget _buildReportCard(Report report) {
    final bool isCompleted = report.isCompleted;

    // Color & progress value based on status
    final Color statusColor = isCompleted ? AppColors.success : Colors.orange;
    final double progressValue = isCompleted ? 1.0 : 0.5;

    // Dummy description until backend provides it
    const String dummyDescription =
        'تم ارسال مشكلتك للجهه المختصه الان و سيتم معالجتها و التحرك فورا';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date ──
          Text(report.formattedDate,
              style: AppTextStyles.x3(color: AppColors.x3)),
          SizedBox(height: 8.h),

          // ── Title ──
          AppText.h2(report.displayTitle, color: AppColors.h2),
          SizedBox(height: 4.h),

          // ── Ticket number ──
          AppText.x3(report.ticketNumber,
              color: AppColors.primary, fullWidth: false),
          SizedBox(height: 12.h),

          // ── Image + Description ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  report.imageUrl,
                  width: 120.w,
                  height: 60.h,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120.w,
                    height: 60.h,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported,
                        color: Colors.grey, size: 28.r),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  dummyDescription,
                  style: AppTextStyles.x3(color: AppColors.x1)
                      .copyWith(height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ── Status label ──
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                report.status,
                style: AppTextStyles.x2().copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // ── Progress bar ──
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 6.h,
            ),
          ),
        ],
      ),
    );
  }
}