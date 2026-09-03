import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/styling/app_colors.dart';

class PageDots extends StatelessWidget {
  final int activeIndex;

  const PageDots({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index == activeIndex;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? 24.w : 10.w,
          height: 10.h,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.x3,
            borderRadius: BorderRadius.circular(5.r),
          ),
        );
      }),
    );
  }
}
