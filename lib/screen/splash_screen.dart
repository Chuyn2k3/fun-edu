import 'package:flutter/material.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    final isFirstTime =
        GetIt.instance.get<SharedPreferencesManager>().getBool('isFirstTime') ??
            true;
    final deviceId =
        GetIt.instance.get<SharedPreferencesManager>().getString('deviceId');

    Future.delayed(
      const Duration(seconds: 1),
      () {
        context.pushNamed((isFirstTime || deviceId == null)
            ? GoRouterName.onboard.routeName
            : GoRouterName.tabbar.routeName);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animation/MainSplashAnimation.json',
          height: 420,
          width: 300,
        ),
      ),
    );
  }
}
