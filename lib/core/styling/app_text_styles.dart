import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors.dart';

class AppTextStyles {
  /// H1 - Tajawal Bold, 24sp
  static TextStyle h1({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.bold,
        fontSize: 24.sp,
        color: color ?? AppColors.h1,
        height: 1.3,
      );

  /// H2 - Tajawal Medium, 20sp
  static TextStyle h2({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w500,
        fontSize: 20.sp,
        color: color ?? AppColors.h2,
        height: 1.25,
      );

  /// X1 - Tajawal Regular, 16sp
  static TextStyle x1({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w500,
        fontSize: 16.sp,
        color: color ?? AppColors.x1,
        height: 1.25,
      );

  /// X2 - Tajawal Regular, 14sp
  static TextStyle x2({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w400,
        fontSize: 14.sp,
        color: color ?? AppColors.x2,
        height: 1.25,
      );

  /// X3 - Tajawal Regular, 12sp
  static TextStyle x3({Color? color}) => TextStyle(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.w400,
        fontSize: 12.sp,
        color: color ?? AppColors.x3,
        height: 1.25,
      );
}
