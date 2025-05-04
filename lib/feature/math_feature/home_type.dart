import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/game/space_game.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/math_screen.dart';
import 'package:get/get.dart';

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
        MathLearnType.spaceGame => EdgeInsets.all(16),
        MathLearnType.quiz => EdgeInsets.all(16),
      };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      MathLearnType.spaceGame => () =>
          Get.to(() => const SpaceGameScreen()),
      MathLearnType.quiz => () => Get.to(() => const MathScreen()),
      //Get.snackbar("Thông báo", "Tính năng chưa hỗ trợ"),
    };
  }
}
