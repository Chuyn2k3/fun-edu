import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/screen/math_screen.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:go_router/go_router.dart';

enum MathLearnType { spaceGame, quiz }

extension MyMathLearnType on MathLearnType {
  //title
  String get title => switch (this) {
        MathLearnType.spaceGame => 'CHINH PHỤC THỬ THÁCH',
        MathLearnType.quiz => 'LUYỆN PHÉP TÍNH',
      };

  //lottie
  String get image => switch (this) {
        MathLearnType.spaceGame => 'video_player.png',
        MathLearnType.quiz => 'math.png',
      };

  String get desc => switch (this) {
        MathLearnType.spaceGame => 'Luyện tập phép cộng trừ trong phạm vi 10',
        MathLearnType.quiz => 'Luyện tập các phép toán',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        MathLearnType.spaceGame => true,
        MathLearnType.quiz => false,
      };

  //for padding
  EdgeInsets get padding => switch (this) {
        MathLearnType.spaceGame => const EdgeInsets.all(16),
        MathLearnType.quiz => const EdgeInsets.all(16),
      };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      MathLearnType.spaceGame => () =>
          getContext.pushNamed(GoRouterName.mathGame.routeName),
      MathLearnType.quiz => () {
          Navigator.push(
              getContext,
              MaterialPageRoute(
                builder: (context) => const MathScreen(),
              ));
          // => Get.to(() => const MathScreen()),
        }
    };
  }
}
