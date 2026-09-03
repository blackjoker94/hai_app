import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showText = false;
  Timer? _textTimer;

  @override
  void initState() {
    super.initState();

    // Fade in text after bounce finishes
    _textTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _showText = true);
    });
  }

  @override
  void dispose() {
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDC8F5A), AppColors.primary],
            stops: [0.0, 0.9],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 3.0, end: 0.0),
              duration: const Duration(milliseconds: 4500),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, value * 200),
                  child: child,
                );
              },
              child: SvgPicture.asset(
                AppImages.logo,
                width: 90.w,
                height: 120.h,
                fit: BoxFit.contain,
              ),
            ),

            Padding(
              padding: AppPadding.verticalPadding(20),
              child: AnimatedOpacity(
                opacity: _showText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 800),
                child: Text(
                  'بيك الحيّ هيفضل حيّ',
                  style: AppTextStyles.h2(
                    color: AppColors.white,
                  ).copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
