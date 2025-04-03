import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/game_feature/game/dino_run/pages/page_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/offline_multiplayer_screen.dart';
import 'package:fun_edu/feature/game_feature/game/multi_player_quiz/page.dart';
import 'package:fun_edu/feature/game_feature/game/sweep/game/helper/colors.dart';
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
        return "dino.jpg";
      case GameEnum.sweep:
        return "game_sweep.png";
      case GameEnum.soloQuiz:
        return "dual_quiz.jpg";
    }
  }

  String get getName {
    switch (this) {
      case GameEnum.dinoRun:
        return "Khủng Long Thoát Hiểm";
      case GameEnum.sweep:
        return "Dọn sạch đại dương";
      case GameEnum.soloQuiz:
        return "Đố Vui Đọ Não";
    }
  }

  // Color get color => switch (this) {
  //       GameEnum.dinoRun => ColorBase.accent7,
  //       GameEnum.sweep => ColorBase.accent2,
  //       GameEnum.soloQuiz => ColorBase.accent8,
  //     };
  // Color get colorB => switch (this) {
  //       GameEnum.dinoRun => ColorBase.accent7B,
  //       GameEnum.sweep => ColorBase.accent2B,
  //       GameEnum.soloQuiz => ColorBase.accent8B,
  //     };
  Color get color {
    switch (this) {
      case GameEnum.dinoRun:
        return ColorBase.accent7; // Đỏ tươi
      case GameEnum.sweep:
        // return Color(0xFF4FC3F7); // Xanh dương sáng (Gợi ý 1)
        return const Color(
            0xFF64B5F6); // Xanh dương sáng hơn một chút (Blue 300) - Cân nhắc
      case GameEnum.soloQuiz:
        return ColorBase.accent3; // Trắng
      default: // Thêm default hoặc xử lý các case khác nếu cần
        return Colors.grey;
    }
  }

  Color get colorB {
    switch (this) {
      case GameEnum.dinoRun:
        return ColorBase.accent7B; // Đỏ đậm
      case GameEnum.sweep:
        return ColorBase.secondary; // Xanh dương đậm làm điểm nhấn
      case GameEnum.soloQuiz:
        // return ColorBase.secondary; // Xanh dương đậm làm điểm nhấn (Gợi ý 1)
        // return const Color(0xFF757575); // Hoặc một màu xám trung bình nếu muốn trung tính hơn
        return ColorBase.accent3B; // Hoặc thử màu vàng đậm này xem sao?
      default: // Thêm default hoặc xử lý các case khác nếu cần
        return Colors.black;
    }
  }
  // Color get color => switch (this) {
  //       GameEnum.dinoRun => AppColors.orange, // Cam đậm
  //       GameEnum.sweep => AppColors.sweepFill, // Xanh dương sáng
  //       GameEnum.soloQuiz => AppColors.white, // Trắng
  //     };

  // Color get colorB => switch (this) {
  //       GameEnum.dinoRun => AppColors.orangeLight, // Cam nhạt
  //       GameEnum.sweep => AppColors.sweepBorder, // Xanh dương đậm
  //       GameEnum.soloQuiz => AppColors.background, // Xanh nhạt
  //     };

  bool get leftAlign => switch (this) {
        GameEnum.dinoRun => true,
        GameEnum.sweep => false,
        GameEnum.soloQuiz => true,
      };
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
