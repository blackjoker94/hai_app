import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/notification/data/model/notification_model.dart';
import 'package:hai_app/features/notification/presentation/cubit/notifications_cubit.dart';
import 'package:hai_app/features/notification/presentation/cubit/notifications_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    // Provide the Cubit to the widget tree
    return BlocProvider(
      create: (context) => NotificationsCubit(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Column(
          children: [
            SizedBox(height: 16.h),
            // Top Action Bar (Wrapped in Builder to access Cubit context)
            _buildActionHeader(),
            SizedBox(height: 16.h),
            // List of Notifications
            Expanded(
              child: BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  if (state is NotificationsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }
                  if (state is NotificationsLoaded) {
                    return ListView.separated(
                      padding: AppPadding.symmetricPadding(16, 0),
                      itemCount: state.notifications.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 24.h),
                      itemBuilder: (context, index) {
                        final item = state.notifications[index];
                        return _buildNotificationItem(context, item);
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 90,
      backgroundColor: AppColors.card,
      elevation: 0,
      centerTitle: true,
      leadingWidth: 70.w,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.black.withOpacity(0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              AppImages.rightArrow,
              width: 20.w,
              color: AppColors.h1,
            ),
          ),
        ),
      ),
      title: AppText.h1('نود اخبارك بأن', fullWidth: false),
    );
  }

  Widget _buildActionHeader() {
    return Builder(
      builder: (context) {
        return Padding(
          padding: AppPadding.horizontalPadding(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الكل", style: AppTextStyles.x2(color: AppColors.x1)),
              GestureDetector(
                onTap: () {
                  // ✅ Call Cubit
                  context.read<NotificationsCubit>().markAllAsRead();
                },
                child: Text(
                  "اقرأ الكل",
                  style: AppTextStyles.x2(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel item) {
    return InkWell(
      onTap: () {
        // ✅ Call Cubit
        context.read<NotificationsCubit>().markItemAsRead(item.id);
      },
      overlayColor: MaterialStateProperty.all(Colors.transparent),
      child: Padding(
        padding: AppPadding.horizontalPadding(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The Dot Indicator
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Container(
                width: 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isRead ? AppColors.x3 : AppColors.primary,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            // The Text Content
            Expanded(
              child: Text(
                item.text,
                textAlign: TextAlign.right, // Ensure RTL alignment
                style:
                    AppTextStyles.x2(
                      color: item.isRead ? AppColors.h2 : Colors.black,
                    ).copyWith(
                      height: 1.5,
                      fontWeight: item.isRead
                          ? FontWeight.normal
                          : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
