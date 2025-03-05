import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fun_edu/core/colors/app_colors.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/helper/ad_helper.dart';
import 'package:fun_edu/helper/pref.dart';
import 'package:fun_edu/routes.dart';
import 'package:fun_edu/screen/splash_screen.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_it/get_it.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  // init hive
  await Pref.initialize();
  // for initializing facebook ads sdk
  AdHelper.init();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(const MyApp());
}

final navigatorKey = GetIt.instance<NavigationService>().navigatorKey;

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final appColors = AppColors.light();
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: Pref.defaultTheme,

      //dark
      darkTheme: ThemeData(
          useMaterial3: false,
          brightness: Brightness.dark,
          appBarTheme: const AppBarTheme(
            elevation: 1,
            centerTitle: true,
            titleTextStyle:
                TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          )),

      //light
      theme: ThemeData(
          useMaterial3: false,
          appBarTheme: const AppBarTheme(
            elevation: 1,
            centerTitle: true,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.blue),
            titleTextStyle: TextStyle(
                color: Colors.blue, fontSize: 20, fontWeight: FontWeight.w500),
          )),
      navigatorKey: navigatorKey,
      routes: routes,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: SplashScreen(),
      ),
    );
  }
}
