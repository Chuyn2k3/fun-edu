import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fun_edu/cubit/sidebar/sidebar_cubit.dart';
import 'package:fun_edu/di/locator.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_screen_web.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_select_mode.dart';
import 'package:fun_edu/feature/digit_feature/math/index.dart';
import 'package:fun_edu/feature/digit_feature/number/digit_number.dart';
import 'package:fun_edu/feature/even_old_game/even-odd-game-screen_web.dart';
import 'package:fun_edu/feature/even_old_game/even_odd_game_select_mode.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/pages/dino_run_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/page.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/pages/sweep_screen.dart';
import 'package:fun_edu/feature/math_feature/game/space_game.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/ask_operator.dart';
import 'package:fun_edu/feature/number_feature/match_image.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:fun_edu/feature/number_feature/sort_number.dart';
import 'package:fun_edu/feature/number_feature/sound_learn.dart';
import 'package:fun_edu/feature/operation_feature/compare_number.dart';
import 'package:fun_edu/feature/operation_feature/compare_number_by_image.dart';
import 'package:fun_edu/feature/operation_feature/operator_screen.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/screen/choose_age.dart';
import 'package:fun_edu/screen/daily_task_screen.dart';
import 'package:fun_edu/screen/enter_name_widget.dart';
import 'package:fun_edu/screen/home_main_page.dart';
import 'package:fun_edu/screen/onboarding_screen.dart';
import 'package:fun_edu/screen/overview.dart';
import 'package:fun_edu/screen/splash_screen.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

class AppRouter {
  late final GoRouter router = GoRouter(
    navigatorKey: GetIt.instance<NavigationService>().navigatorKey,
    routerNeglect: true,
    debugLogDiagnostics: true,
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text("Page not found"))),
    routes: <GoRoute>[
      GoRoute(
        path: GoRouterName.splashScreen.routePath,
        name: GoRouterName.splashScreen.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: SplashScreen()),
      ),
      GoRoute(
        path: GoRouterName.onboard.routePath,
        name: GoRouterName.onboard.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: OnboardingScreen()),
      ),
      GoRoute(
        path: GoRouterName.nameScreen.routePath,
        name: GoRouterName.nameScreen.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: EnterNameWidget()),
      ),
      GoRoute(
        path: GoRouterName.ageScreen.routePath,
        name: GoRouterName.ageScreen.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: ChooseAgeWidget()),
      ),
      GoRoute(
        path: GoRouterName.tabbar.routePath,
        name: GoRouterName.tabbar.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: HomeMainPage()),
      ),
      GoRoute(
        path: GoRouterName.dailyTask.routePath,
        name: GoRouterName.dailyTask.routeName,
        pageBuilder: (context, state) {
          final userCoin = state.queryParams["userCoin"] as String;
          return MaterialPage<void>(
              child: DailyTaskScreen(userCoin: int.parse(userCoin)));
        },
      ),
      GoRoute(
        path: GoRouterName.numberStudy.routePath,
        name: GoRouterName.numberStudy.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: NumsScreen()),
      ),
      GoRoute(
        path: GoRouterName.numberByAudio.routePath,
        name: GoRouterName.numberByAudio.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: SoundLearnScreen()),
      ),
      GoRoute(
        path: GoRouterName.numberByMatchImage.routePath,
        name: GoRouterName.numberByMatchImage.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: EnhancedMatchImage()),
      ),
      GoRoute(
        path: GoRouterName.numberBySort.routePath,
        name: GoRouterName.numberBySort.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: SortNumber()),
      ),
      GoRoute(
        path: GoRouterName.operationStudy.routePath,
        name: GoRouterName.operationStudy.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: CompareMainScreen()),
      ),
      GoRoute(
        path: GoRouterName.compareNumber.routePath,
        name: GoRouterName.compareNumber.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: CompareNumberScreen()),
      ),
      GoRoute(
        path: GoRouterName.compareNumberByImage.routePath,
        name: GoRouterName.compareNumberByImage.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: EnhancedCompareGameScreen()),
      ),
      GoRoute(
        path: GoRouterName.mathStudy.routePath,
        name: GoRouterName.mathStudy.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: MathFeature()),
      ),
      GoRoute(
        path: GoRouterName.mathGame.routePath,
        name: GoRouterName.mathGame.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: SpaceGameScreen()),
      ),
      GoRoute(
          path: GoRouterName.pdf.routePath,
          name: GoRouterName.pdf.routeName,
          pageBuilder: (context, state) {
            return const MaterialPage<void>(child: AskOperator(isQuiz: false));
          }),
      GoRoute(
          path: GoRouterName.quiz.routePath,
          name: GoRouterName.quiz.routeName,
          pageBuilder: (context, state) =>
              const MaterialPage<void>(child: AskOperator(isQuiz: true))),
      GoRoute(
        path: GoRouterName.evenOdd.routePath,
        name: GoRouterName.evenOdd.routeName,
        pageBuilder: (context, state) => MaterialPage<void>(
          child: kIsWeb
              ? ChangeNotifierProvider(
                  create: (_) => GameProvider(),
                  child: const EvenOddGameScreenWeb(),
                )
              : const EvenOddGameSelectMode(),
        ),
      ),
      GoRoute(
        path: GoRouterName.countShape.routePath,
        name: GoRouterName.countShape.routeName,
        pageBuilder: (context, state) => MaterialPage<void>(
          child: kIsWeb
              ? ChangeNotifierProvider(
                  create: (_) => GameProvider(),
                  child: const CountShapesGameScreenWeb(),
                )
              : const CountShapeGameSelectMode(),
        ),
      ),
      GoRoute(
        path: GoRouterName.digitNumber.routePath,
        name: GoRouterName.digitNumber.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: DigitNumberScreen()),
      ),
      GoRoute(
        path: GoRouterName.digitMath.routePath,
        name: GoRouterName.digitMath.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: DigitMath()),
      ),
      GoRoute(
        path: GoRouterName.dinoRun.routePath,
        name: GoRouterName.dinoRun.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: DinoRunScreen()),
      ),
      GoRoute(
        path: GoRouterName.multiPlayerQuiz.routePath,
        name: GoRouterName.multiPlayerQuiz.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: MultiPlayerQuizScreen()),
      ),
      GoRoute(
        path: GoRouterName.sweep.routePath,
        name: GoRouterName.sweep.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: SweepScreen()),
      ),
      GoRoute(
        path: GoRouterName.overView.routePath,
        name: GoRouterName.overView.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: OverviewScreen()),
      ),
    ],
    redirect: (_, state) {
      _handleSelectRoute(state);

      //  return GoRouterName.overView.routePath;
    },
  );
  void _handleSelectRoute(GoRouterState state) {
    final subloc = state.subloc;
    final sidebarCubit = serviceLocator<SidebarCubit>();
    sidebarCubit.selectSidebarBy(subloc);
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
