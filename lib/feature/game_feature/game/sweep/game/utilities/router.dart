// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';

// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:sweep/game/pages/game_page.dart';
// import 'package:sweep/screens/splash_screen.dart';

// // GoRouter configuration
// final routerProvider = Provider<GoRouter>((ref) {
//   return GoRouter(
//     debugLogDiagnostics: true,
//     redirect: (context, state) {
//       return '/home/game';
//     },
//     routes: [
//       GoRoute(
//         path: '/',
//         builder: (context, state) => const SplashScreen(),
//       ),
//       GoRoute(
//         path: '/home/game',
//         pageBuilder: (context, state) => CustomTransitionPage<void>(
//           key: state.pageKey,
//           child: const GamePage(),
//           transitionsBuilder: (context, animation, secondaryAnimation, child) =>
//               FadeTransition(opacity: animation, child: child),
//         ),
//       ),
//     ],
//   );
// });
