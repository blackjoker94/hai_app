import 'package:flutter/material.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';

class AppText {
  /// 🟩 H1 text widget
  static Widget h1(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool fullWidth = true,
  }) =>
      SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Text(
          text,
          textAlign: textAlign ?? TextAlign.start,
          style: AppTextStyles.h1(color: color).copyWith(
            fontWeight: fontWeight,
          ),
        ),
      );

  /// 🟩 H2 text widget
  static Widget h2(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool fullWidth = true,
  }) =>
      SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Text(
          text,
          textAlign: textAlign ?? TextAlign.start,
          style: AppTextStyles.h2(color: color).copyWith(
            fontWeight: fontWeight,
          ),
        ),
      );

  /// 🟩 X1 text widget
  static Widget x1(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool fullWidth = true,
  }) =>
      SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Text(
          text,
          textAlign: textAlign ?? TextAlign.start,
          style: AppTextStyles.x1(color: color).copyWith(
            fontWeight: fontWeight,
          ),
        ),
      );

  /// 🟩 X2 text widget
  static Widget x2(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool fullWidth = true,
  }) =>
      SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Text(
          text,
          textAlign: textAlign ?? TextAlign.start,
          style: AppTextStyles.x2(color: color).copyWith(
            fontWeight: fontWeight,
          ),
        ),
      );

  /// 🟩 X3 text widget
  static Widget x3(
    String text, {
    Color? color,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    bool fullWidth = true,
  }) =>
      SizedBox(
        width: fullWidth ? double.infinity : null,
        child: Text(
          text,
          textAlign: textAlign ?? TextAlign.start,
          style: AppTextStyles.x3(color: color).copyWith(
            fontWeight: fontWeight,
          ),
        ),
      );
}
