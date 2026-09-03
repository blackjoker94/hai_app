import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_cubit.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_state.dart';
import 'package:hai_app/features/auth/presentation/widgets/app_textfield.dart';
import 'package:hai_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:hai_app/features/auth/presentation/widgets/page_dots.dart';
import 'package:hai_app/features/welcomeboard/presentation/widgets/app_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final addressController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    nationalIdController.dispose();
    addressController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is SignupSuccess) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.idCard,
                  (route) => false,
                );
              }

              if (state is SignupError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error)),
                );
              }
            },
            builder: (context, state) {
              final cubit = context.read<AuthCubit>();

              return SingleChildScrollView(
                child: Padding(
                  padding: AppPadding.symmetricPadding(16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const PageDots(activeIndex: 2),
                      SizedBox(height: 30.h),

                      /// White Card
                      Container(
                        width: 343.w,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border:
                              Border.all(color: Colors.grey.shade300, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 20.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AppText.h1(
                                  'من فضلك أدخل بياناتك لتكملة التسجيل'),
                              SizedBox(height: 8.h),
                              AppText.x2(
                                'نريد أن نعرف عنك بشكل أفضل، ونساعدك في تسجيل الدخول',
                              ),
                              SizedBox(height: 24.h),

                              /// Full Name
                              AppText.x1('اكتب اسمك الثلاثي كما هو في البطاقة'),
                              SizedBox(height: 6.h),
                              AppTextfield(
                                hintText: 'الاسم',
                                controller: nameController,
                                keyboardType: TextInputType.name,
                              ).copyWith(backgroundColor: Colors.white),
                              SizedBox(height: 12.h),

                              /// National ID
                              AppText.x1(
                                  'اكتب رقمك القومي المكون من 14 رقمًا'),
                              SizedBox(height: 6.h),
                              AppTextfield(
                                hintText: 'الرقم القومي',
                                controller: nationalIdController,
                                keyboardType: TextInputType.number,
                              ).copyWith(backgroundColor: Colors.white),
                              SizedBox(height: 12.h),

                              /// Address
                              AppText.x1(
                                  'اكتب عنوان سكنك بالتفصيل (الشارع - الحي)'),
                              SizedBox(height: 6.h),
                              AppTextfield(
                                hintText: 'العنوان',
                                controller: addressController,
                              ).copyWith(backgroundColor: Colors.white),
                              SizedBox(height: 12.h),

                              /// Email
                              AppText.x1('اكتب بريدك الإلكتروني'),
                              SizedBox(height: 6.h),
                              AppTextfield(
                                hintText: 'البريد الإلكتروني',
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                              ).copyWith(backgroundColor: Colors.white),
                              SizedBox(height: 12.h),

                              /// Password
                              AppText.x1('اكتب كلمة المرور'),
                              SizedBox(height: 6.h),
                              AppTextfield(
                                hintText: 'كلمة المرور',
                                controller: passwordController,
                                obscureText: true,
                              ).copyWith(backgroundColor: Colors.white),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 30.h),

                      /// Buttons
                      SizedBox(
                        width: 343.w,
                        height: 48.h,
                        child: state is SignupLoading
                            ? const Center(child: CircularProgressIndicator())
                            : AppButton(
                                text: 'تحقق',
                                onTap: () {
                                  cubit.emitSignupStates(
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                    address: addressController.text.trim(),
                                    nationalId:
                                        nationalIdController.text.trim(),
                                  );
                                },
                              ),
                      ),

                      SizedBox(height: 12.h),

                      AuthButton(
                        text: 'إلغاء',
                        btnColor: AppColors.card,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),

                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}