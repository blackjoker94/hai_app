import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/features/home/presentation/screens/home_screen.dart';
import 'package:hai_app/features/profile/presentation/screens/profile_screen.dart';

class HomeRoot extends StatefulWidget {
  const HomeRoot({super.key});

  @override
  State<HomeRoot> createState() => _HomeRootState();
}

class _HomeRootState extends State<HomeRoot> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [HomeScreen(), ProfileScreen()];

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _onCenterPressed() {
    Navigator.pushNamed(context, RouteNames.posts);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onHomeTap: () => _onTabSelected(0),
        onProfileTap: () => _onTabSelected(1),
        onCenterTap: _onCenterPressed,
      ),
      extendBody: true,
      backgroundColor: AppColors.background,
    );
  }
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onHomeTap;
  final VoidCallback onProfileTap;
  final VoidCallback onCenterTap;

  const _CustomBottomNavBar({
    required this.currentIndex,
    required this.onHomeTap,
    required this.onProfileTap,
    required this.onCenterTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        // only horizontal padding, no extra bottom so bar goes lower
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SizedBox(
            height: 90.h,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // White rounded bar background
                Container(
                  height: 68.h,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home (right side in RTL)
                      InkWell(
                        onTap: onHomeTap,
                        borderRadius: BorderRadius.circular(18.r),
                        child: _SideNavItem(
                          icon: SvgPicture.asset(
                            AppImages.home,
                            width: 20.w,
                            height: 20.h,
                            color: currentIndex == 0
                                ? AppColors.primary
                                : Colors.black,
                          ),
                          label: 'الرئيسية',
                          isSelected: currentIndex == 0,
                        ),
                      ),
                      SizedBox(width: 80.w), // space for center pill
                      // Profile (left side)
                      InkWell(
                        onTap: onProfileTap,
                        borderRadius: BorderRadius.circular(18.r),
                        child: _SideNavItem(
                          icon: SvgPicture.asset(
                            AppImages.profile,
                            width: 20.w,
                            height: 20.h,
                            color: currentIndex == 1
                                ? AppColors.primary
                                : Colors.black,
                          ),
                          label: 'البروفايل',
                          isSelected: currentIndex == 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center orange pill button
                Positioned(
                  top: 10.h, // adjust this to move it up/down
                  child: GestureDetector(
                    onTap: onCenterTap,
                    child: _CenterNavButton(
                      primary: AppColors.primary,
                      isActive: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isSelected;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isSelected ? AppColors.primary : Colors.black;

    return Container(
      width: 100.w,
      height: 56.h,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // small top indicator
          Container(
            height: 3.h,
            width: 24.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 6.h),
          icon,
          SizedBox(height: 4.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CenterNavButton extends StatelessWidget {
  final Color primary;
  final bool isActive;

  const _CenterNavButton({required this.primary, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.w,
      height: 72.h,
      decoration: BoxDecoration(
        // base orange + shadow
        color: primary,
        borderRadius: BorderRadius.circular(26.r),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.45),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
        // white-lines + shapes background image
        image: const DecorationImage(
          image: AssetImage(AppImages.navCenterBg),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, color: Colors.white),
          SizedBox(height: 4.h),
          const Text(
            'بلّغ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


