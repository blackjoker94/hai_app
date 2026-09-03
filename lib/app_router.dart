import 'package:flutter/material.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/features/auth/presentation/screens/app_start_wrapper.dart';
import 'package:hai_app/features/auth/presentation/screens/id_card_screen.dart';
import 'package:hai_app/features/auth/presentation/screens/login_screen.dart';
import 'package:hai_app/features/auth/presentation/screens/signup_screen.dart';
import 'package:hai_app/features/chat/presentation/screens/chat_screen.dart';
import 'package:hai_app/features/coupons/presentation/screens/coupons_screen.dart';
import 'package:hai_app/features/post/presentation/screens/post_screen.dart';
import 'package:hai_app/features/home/presentation/widgets/home_root.dart';
import 'package:hai_app/features/notification/presentation/screens/notifications_screen.dart'; // Check your folder name (notification vs notifications)
import 'package:hai_app/features/report/presentation/screens/my_report_screen.dart';
import 'package:hai_app/features/welcomeboard/presentation/screens/welcome_board.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return MaterialPageRoute(builder: (_) => const AppStartWrapper());
      case RouteNames.welcomeBoard:
        return MaterialPageRoute(builder: (_) => const WelcomeBoard());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RouteNames.signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case RouteNames.idCard:
        return MaterialPageRoute(builder: (_) => const IdCardScreen());
      case RouteNames.homeRoot:
        return MaterialPageRoute(builder: (_) => const HomeRoot());
      case RouteNames.chat:
        final args = settings.arguments as Map<String, dynamic>?; // ← FIX
        return MaterialPageRoute(
          builder: (_) =>
              ChatScreen(reportLabel: args?['reportLabel'] as String?),
        );
      case RouteNames.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case RouteNames.myReports:
        return MaterialPageRoute(builder: (_) => const MyReportsScreen());
      case RouteNames.coupons:
        return MaterialPageRoute(builder: (_) => const CouponsScreen());
      case RouteNames.posts:
        return MaterialPageRoute(builder: (_) => const PostScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('404 - Page not found'))),
        );
    }
  }
}
