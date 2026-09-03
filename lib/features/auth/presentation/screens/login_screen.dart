import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/core/styling/app_images.dart';
import 'package:hai_app/core/styling/app_padding.dart';
import 'package:hai_app/core/styling/app_text.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_cubit.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_state.dart';
import 'package:hai_app/features/auth/presentation/widgets/app_textfield.dart';
import 'package:hai_app/features/auth/presentation/widgets/auth_button.dart';
import 'package:hai_app/features/welcomeboard/presentation/widgets/app_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.homeRoot,
                (route) => false,
              );
            }

            if (state is LoginError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          builder: (context, state) {
            final cubit = context.read<AuthCubit>();

            return Padding(
              padding: AppPadding.symmetricPadding(16, 50),
              child: SingleChildScrollView(
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

                    SizedBox(height: 90.h),

                    AppTextfield(
                      hintText: 'ادخل بريدك الإلكتروني',
                      svgIconPath: AppImages.email,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    SizedBox(height: 28.h),

                    AppTextfield(
                      hintText: 'ادخل كلمه المرور',
                      svgIconPath: AppImages.password,
                      obscureText: true,
                      controller: passwordController,
                    ),

                    SizedBox(height: 28.h),

                    state is LoginLoading
                        ? const CircularProgressIndicator()
                        : AppButton(
                            text: 'تسجيل الدخول',
                            onTap: () {
                              cubit.emitLoginStates(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                            },
                          ),

                    SizedBox(height: 23.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: false,
                              activeColor: AppColors.primary,
                              side: const BorderSide(
                                width: 1.3,
                                color: AppColors.x3,
                              ),
                              visualDensity: VisualDensity.compact,
                              onChanged: (value) {},
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            AppText.x3(
                              'تذكرني',
                              fullWidth: false,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: AppText.x2(
                            'هل نسيت كلمه المرور',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                            fullWidth: false,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppColors.x2,
                            thickness: 2,
                            indent: 24,
                            endIndent: 4,
                          ),
                        ),
                        AppText.x2(
                          'Or',
                          color: AppColors.x3,
                          fontWeight: FontWeight.w500,
                          fullWidth: false,
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppColors.x2,
                            thickness: 2,
                            indent: 4,
                            endIndent: 24,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 28.h),

                    AuthButton(
                      text: 'تسجيل الدخول بواسطة جوجل',
                      svgAsset: AppImages.googleLogo,
                      onTap: () {},
                    ),

                    SizedBox(height: 20.h),

                    AuthButton(
                      text: 'تسجيل الدخول بواسطة ابل',
                      svgAsset: AppImages.appleLogo,
                      onTap: () {},
                    ),

                    SizedBox(height: 22.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: AppPadding.startPadding(4),
                          child: AppText.x3(
                            'هل لا تمتلك حساب؟',
                            fullWidth: false,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              RouteNames.signup,
                            );
                          },
                          child: AppText.x3(
                            'انضم لنا',
                            color: AppColors.primary,
                            fullWidth: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
