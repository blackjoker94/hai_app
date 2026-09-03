import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';

class AppTextfield extends StatelessWidget {
  final String hintText;
  final String? svgIconPath;
  final bool obscureText;
  final Color backgroundColor;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const AppTextfield({
    super.key,
    required this.hintText,
    this.svgIconPath,
    this.obscureText = false,
    this.backgroundColor = const Color(0xFFE4E4E4),
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.x3),
      ),
      child: Padding(
        padding: AppPadding.horizontalPadding(10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Tajawal',
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: AppTextStyles.x1(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            prefixIcon: svgIconPath != null && svgIconPath!.isNotEmpty
                ? Padding(
                    padding: EdgeInsets.all(10.w),
                    child: SvgPicture.asset(
                      svgIconPath!,
                      width: 20.w,
                      height: 20.h,
                    ),
                  )
                : null,
            prefixIconConstraints: BoxConstraints(
              minWidth: 40.w,
              minHeight: 40.h,
            ),
          ),
        ),
      ),
    );
  }
  AppTextfield copyWith({
  String? hintText,
  String? svgIconPath,
  bool? obscureText,
  Color? backgroundColor,
  TextEditingController? controller,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  ValueChanged<String>? onChanged,
}) {
  return AppTextfield(
    hintText: hintText ?? this.hintText,
    svgIconPath: svgIconPath ?? this.svgIconPath,
    obscureText: obscureText ?? this.obscureText,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    controller: controller ?? this.controller,
    keyboardType: keyboardType ?? this.keyboardType,
    validator: validator ?? this.validator,
    onChanged: onChanged ?? this.onChanged,
  );
}

}
