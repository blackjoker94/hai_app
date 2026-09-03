import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hai_app/app_router.dart';
import 'package:hai_app/core/di/injection.dart';
import 'package:hai_app/core/helpers/route_names.dart';
import 'package:hai_app/core/services/classification_service.dart';
import 'package:hai_app/core/styling/app_colors.dart';
import 'package:hai_app/firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  
  await configureDependencies();
  
  await Hive.initFlutter();
  await Hive.openBox('cached');
  await Hive.openBox('authBox');
  await getIt<ClassificationService>().loadModel();

  runApp(HaiApp(appRouter: AppRouter()));
}

class HaiApp extends StatelessWidget {
  final AppRouter appRouter;
  const HaiApp({super.key, required this.appRouter});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateRoute: appRouter.generateRoute,
        initialRoute: RouteNames.splash,

        locale: const Locale('ar', 'EG'),
        supportedLocales: const [Locale('ar', 'EG')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),

        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Tajawal',
          scaffoldBackgroundColor: AppColors.background,
        ),
      ),
    );
  }
}
