import 'package:flutter/material.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_select_mode.dart';
import 'package:fun_edu/feature/digit_feature/math/index.dart';
import 'package:fun_edu/feature/digit_feature/number/digit_number.dart';
import 'package:fun_edu/feature/even_old_game/even_odd_game_select_mode.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/pages/dino_run_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/page.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/pages/sweep_screen.dart';
import 'package:fun_edu/feature/math_feature/game/space_game.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/number_feature/match_image.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:fun_edu/feature/number_feature/sort_number.dart';
import 'package:fun_edu/feature/number_feature/sound_learn.dart';
import 'package:fun_edu/feature/operation_feature/compare_number.dart';
import 'package:fun_edu/feature/operation_feature/compare_number_by_image.dart';
import 'package:fun_edu/feature/operation_feature/operator_screen.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/screen/choose_age.dart';
import 'package:fun_edu/screen/daily_task_screen.dart';
import 'package:fun_edu/screen/enter_name_widget.dart';
import 'package:fun_edu/screen/home_main_page.dart';
import 'package:fun_edu/screen/onboarding_screen.dart';
import 'package:fun_edu/screen/splash_screen.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

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
            const MaterialPage<void>(child: MatchImage()),
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
            const MaterialPage<void>(child: CompareImageScreen()),
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
//       GoRoute(
//         path: GoRouterName.pdf.routePath,
//         name: GoRouterName.pdf.routeName,
//         pageBuilder: (context, state) {
// final isQuiz= state.queryParams
//           return const MaterialPage<void>(child: AskOperator()),
//         }

//       ),
//       GoRoute(
//         path: GoRouterName.quiz.routePath,
//         name: GoRouterName.quiz.routeName,
//         pageBuilder: (context, state) =>
//             const MaterialPage<void>(child: QuizScreen()),
//       ),
      GoRoute(
        path: GoRouterName.evenOdd.routePath,
        name: GoRouterName.evenOdd.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: EvenOddGameSelectMode()),
      ),
      GoRoute(
        path: GoRouterName.countShape.routePath,
        name: GoRouterName.countShape.routeName,
        pageBuilder: (context, state) =>
            const MaterialPage<void>(child: CountShapeGameSelectMode()),
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
    ],
  );
}
