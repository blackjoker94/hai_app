import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_cubit.dart';
import 'package:hai_app/features/auth/presentation/cubits/auth_cubit/auth_state.dart';
import 'package:hai_app/features/splash/presentation/screens/splash_screen.dart';

class AppStartWrapper extends StatelessWidget {
  const AppStartWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>()..checkSession(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is SessionAuthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.homeRoot,
              (route) => false,
            );
          } else if (state is SessionUnauthenticated) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              RouteNames.login,
              (route) => false,
            );
          }
        },
        // Show your existing splash screen visuals here while checking.
        // The navigation fires automatically once checkSession() completes.
        child: const SplashScreen(),
      ),
    );
  }
}