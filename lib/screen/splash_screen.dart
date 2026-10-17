// import 'package:flutter/material.dart';
// import 'package:fun_edu/router/go_router_name_enum.dart';
// import 'package:fun_edu/utils/base_scaffold.dart';
// import 'package:fun_edu/utils/shared_preferences_manager.dart';
// import 'package:get_it/get_it.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lottie/lottie.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     final isFirstTime =
//         GetIt.instance.get<SharedPreferencesManager>().getBool('isFirstTime') ??
//             true;
//     final deviceId =
//         GetIt.instance.get<SharedPreferencesManager>().getString('deviceId');

//     Future.delayed(
//       const Duration(seconds: 1),
//       () {
//         context.pushNamed(GoRouterName.tabbar.routeName);
//         // context.pushNamed((isFirstTime || deviceId == null)
//         //     ? GoRouterName.onboard.routeName
//         //     : GoRouterName.tabbar.routeName);
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BaseScaffold(
//       body: Center(
//         child: Lottie.asset(
//           'assets/animation/MainSplashAnimation.json',
//           height: 420,
//           width: 300,
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/base_scaffold.dart';
import 'package:fun_edu/utils/shared_preferences_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    Future.delayed(const Duration(seconds: 2), () {
      final isFirstTime =
          GetIt.instance.get<SharedPreferencesManager>().getBool('isFirstTime') ?? true;
      final deviceId =
          GetIt.instance.get<SharedPreferencesManager>().getString('deviceId');

      context.pushReplacementNamed(
        GoRouterName.tabbar.routeName,
        // (isFirstTime || deviceId == null)
        //     ? GoRouterName.onboard.routeName
        //     : GoRouterName.tabbar.routeName,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFAFAFA), Color(0xFFE0F7FA)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'FunEdu',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00796B),
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Khơi nguồn sáng tạo cho trẻ nhỏ',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: 32),
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF00796B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

