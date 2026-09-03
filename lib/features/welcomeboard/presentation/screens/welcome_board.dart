import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/welcomeboard/presentation/widgets/app_button.dart';

class WelcomeBoard extends StatelessWidget {
  const WelcomeBoard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: AppPadding.symmetricPadding(16, 101),
        child: Column(
          children: [
            AppText.h1(
              'مرحبًا بك في حي',
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
            SizedBox(height: 16.h),
            AppText.x1(
              'سجّل الدخول لمتابعة بلاغاتك، وتتبع حالة الإصلاحات لحظة بلحظة، وساهم في تحسين حيّك',
              color: AppColors.h2,
            ),
            SizedBox(height: 211.h),
            // 2.1 Login Button
            AppButton(
              text: 'تسجيل الدخول',
              onTap: () {
                Navigator.pushNamed(context, RouteNames.login);
              },
            ),
            SizedBox(height: 32.h),
            // 3. Guest -> Home
            AppButton(
              text: 'الدخول كزائر',
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.homeRoot,
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
