import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppPadding {
  static EdgeInsets horizontalPadding([double? value]) {
    return EdgeInsets.symmetric(horizontal: (value ?? 16).w);
  }

  static EdgeInsets symmetricPadding([double? width, double? height]) {
    return EdgeInsets.symmetric(
        horizontal: (width ?? 20).w, vertical: (height ?? 20).h);
  }

  static EdgeInsets verticalPadding([double? value]) {
    return EdgeInsets.symmetric(vertical: (value ?? 20).h);
  }

  static EdgeInsets allPadding([double? value]) {
    return EdgeInsets.symmetric(
        vertical: (value ?? 20).h, horizontal: (value ?? 20).w);
  }

  static EdgeInsets topPadding([double? value]) {
    return EdgeInsets.only(top: (value ?? 20).h);
  }

  static EdgeInsets bottomPadding([double? value]) {
    return EdgeInsets.only(bottom: (value ?? 20).h);
  }

  static EdgeInsets startPadding([double? value]) {
    return EdgeInsets.only(left: (value ?? 20).w);
  }

  static EdgeInsets endPadding([double? value]) {
    return EdgeInsets.only(right: (value ?? 20).w);
  }
}
