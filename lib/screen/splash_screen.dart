import 'package:flutter/material.dart';
import 'package:fun_edu/screen/home_main_page.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:lottie/lottie.dart';
import 'onboarding_screen.dart';

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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return (isFirstTime || deviceId == null)
                  ? const OnboardingScreen()
                  : const HomeMainPage();
            },
          ),
        ); // Chuyển hướng sau khi kết thúc splash
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Center(
        child: Lottie.asset(
          'assets/animationSplashScreen/MainSplashAnimation.json',
          height: 420,
          width: 300,
        ),
      ),
    );
  }
}
