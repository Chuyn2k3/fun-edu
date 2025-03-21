import 'package:flutter/material.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/pages/page_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/offline_multiplayer_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/page.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/pages/game_page.dart';
import 'package:fun_edu/utils/navigation_service.dart';

enum GameEnum {
  dinoRun,
  sweep,
  soloQuiz,
  ;

  String get getImage {
    switch (this) {
      case GameEnum.dinoRun:
        return "assets/images/dino.jpg";
      case GameEnum.sweep:
        return "assets/images/game_sweep.png";
      case GameEnum.soloQuiz:
        return "assets/images/dual_quiz.jpg";
    }
  }

  String get getName {
    switch (this) {
      case GameEnum.dinoRun:
        return "Khủng Long Thoát Hiểm";
      case GameEnum.sweep:
        return "Giải cứu đại dương";
      case GameEnum.soloQuiz:
        return "Đố Vui Đọ Não";
    }
  }

  VoidCallback get onTap {
    switch (this) {
      case GameEnum.dinoRun:
        return () {
          Navigator.push(
              getContext,
              MaterialPageRoute(
                builder: (context) => const PageScreen(),
              ));
        };

      case GameEnum.sweep:
        return () {
          Navigator.push(
              getContext,
              MaterialPageRoute(
                builder: (context) => const GamePage(),
              ));
        };
      case GameEnum.soloQuiz:
        return () {
          Navigator.push(
              getContext,
              MaterialPageRoute(
                builder: (context) => const SoloPage(),
              ));
        };
    }
  }
}
