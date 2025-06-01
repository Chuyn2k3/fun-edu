import 'package:flutter/foundation.dart';

enum GoRouterName {
  splashScreen,
  onboard,
  nameScreen,
  ageScreen,
  tabbar,
  dailyTask,
  numberStudy,
  numberByAudio,
  numberByMatchImage,
  numberBySort,
  operationStudy,
  compareNumber,
  compareNumberByImage,
  mathStudy,
  mathGame,
  pdf,
  quiz,
  evenOdd,
  countShape,
  digitNumber,
  digitMath,
  dinoRun,
  multiPlayerQuiz,
  sweep,
  overView
}

extension GoRouterNameX on GoRouterName {
  String get routeName => name;

  String get routePath {
    switch (this) {
      case GoRouterName.splashScreen:
        return kIsWeb ? "/splash-screen" : "/";
      case GoRouterName.onboard:
        return "/onboard";
      case GoRouterName.nameScreen:
        return "/name";
      case GoRouterName.ageScreen:
        return "/age";
      case GoRouterName.tabbar:
        return "/tabbar";
      case GoRouterName.dailyTask:
        return "/daily-task/:userCoin";
      case GoRouterName.numberStudy:
        return "/number-study";
      case GoRouterName.numberByAudio:
        return "/number-by-audio";
      case GoRouterName.numberByMatchImage:
        return "/number-by-match-image";
      case GoRouterName.numberBySort:
        return "/number-by-sort";
      case GoRouterName.operationStudy:
        return "/operation-study";
      case GoRouterName.compareNumber:
        return "/compare-number";
      case GoRouterName.compareNumberByImage:
        return "/compare-number-by-image";
      case GoRouterName.mathStudy:
        return "/math-study";
      case GoRouterName.mathGame:
        return "/math-game";
      case GoRouterName.pdf:
        return "/pdf";
      case GoRouterName.quiz:
        return "/quiz";
      case GoRouterName.evenOdd:
        return "/even-odd";
      case GoRouterName.countShape:
        return "/count-shape";
      case GoRouterName.digitNumber:
        return "/digit-number";
      case GoRouterName.digitMath:
        return "/digit-math";
      case GoRouterName.dinoRun:
        return "/dino-run";
      case GoRouterName.multiPlayerQuiz:
        return "/multi-player-quiz";
      case GoRouterName.sweep:
        return "/sweep";
      case GoRouterName.overView:
        return kIsWeb ? "/" : "/overview";
    }
  }
}
