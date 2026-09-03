import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';

class CouponsScreen extends StatelessWidget {
  const CouponsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            AppImages.rightArrow,
            width: 24.w,
            height: 24.h,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: AppText.h1('الكوبونات', fullWidth: false),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          SizedBox(height: 12.h),
          AppText.h2('لديك 4 كوبونات لهذا الشهر', fullWidth: false),
          _buildCouponCard('يمكنك استبداله بتذكرة مترو سعر 22 جنية',),
          _buildCouponCard('يمكنك استبداله بتذكرة مترو سعر 22 جنية',),
          _buildCouponCard("يمكنك استبداله بتذكرة مونوريل سعر 35 جنيه"),
          _buildCouponCard("يمكنك استبداله ببطاقة التموين الغذائي بقيمة 100 جنيه"),
        ],
      ),
    );
  }
}

Widget _buildCouponCard(String title) {
  return Padding(
    padding: AppPadding.symmetricPadding(18, 18),
    child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.couponBg),
          fit: BoxFit.fill,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 6),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: AppPadding.symmetricPadding(20, 24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// LEFT SIDE (Percentage)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.h1(
                    '50\n%',
                    color: AppColors.primary,
                    fullWidth: false,
                  ),
                  SizedBox(height: 8.h),
                  AppText.x2('ينتهي في 2025/2', fullWidth: false),
                ],
              ),

              SizedBox(width: 16.w),

              /// VERTICAL DASHED LINE
              DottedBorder(
                options: CustomPathDottedBorderOptions(
                  padding: EdgeInsets.zero,
                  color: Colors.black,
                  strokeWidth: 2,
                  dashPattern: const [6, 3],
                  customPath: (size) {
                    return Path()
                      ..moveTo(0, 0)
                      ..lineTo(0, size.height);
                  },
                ),
                child: const SizedBox(width: 1),
              ),

              SizedBox(width: 16.w),

              /// RIGHT SIDE (Text Content)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.x1(
                      title,
                      
                      color: AppColors.primary,
                      fullWidth: false,
                    ),
                    SizedBox(height: 8.h),
                    AppText.x2(
                      'يمكنك استبداله بتذكرة مترو سعر 20 جنية!',
                      fullWidth: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
