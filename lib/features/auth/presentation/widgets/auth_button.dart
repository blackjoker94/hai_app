import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final String? svgAsset;
  final VoidCallback? onTap;
  final Color? btnColor;

  const AuthButton({
    super.key,
    required this.text,
    this.svgAsset,
    required this.onTap,
    this.btnColor = const Color(0xFFE4E4E4),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 343.w,
        height: 52.h,
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(12.r),

          border: Border.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null) ...[
              SvgPicture.asset(svgAsset!, width: 24.w, height: 24.h),
              SizedBox(width: 8.w),
            ],
            Text(
              text,
              style: AppTextStyles.x2(
                color: AppColors.x2,
              ).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
