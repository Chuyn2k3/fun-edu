import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_screen.dart';
import 'package:fun_edu/feature/count_shape_game/count_shape_game_select_mode.dart';
import 'package:fun_edu/feature/even_old_game/even_odd_game_screen.dart';
import 'package:fun_edu/feature/even_old_game/even_odd_game_select_mode.dart';
import 'package:fun_edu/feature/math_feature/game/space_game.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/quiz_screen.dart';
import 'package:fun_edu/feature/operation_feature/compare_number.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:fun_edu/feature/operation_feature/operator_screen.dart';
import 'package:fun_edu/feature/provider/game_provider.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

enum HomeType { number, operation, math, evenOdd, countShape }

extension MyHomeType on HomeType {
  //title
  String get title => switch (this) {
        HomeType.number => 'CHỮ SỐ',
        HomeType.operation => 'PHÉP SO SÁNH',
        HomeType.math => 'PHÉP TÍNH',
        HomeType.evenOdd => "PHÂN BIỆT CHẴN LẺ",
        HomeType.countShape => "ĐUỔI HÌNH BẮT SỐ",
      };

  //lottie
  String get image => switch (this) {
        HomeType.number => 'numbers.png',
        HomeType.operation => 'equal-to-or-greater-than-symbol.png',
        HomeType.math => 'math.png',
        // TODO: Handle this case.
        HomeType.evenOdd => 'odd.png',
        // TODO: Handle this case.
        HomeType.countShape => 'shapes.png',
      };

  String get desc => switch (this) {
        HomeType.number => 'Làm quen với các số từ 0 đến 9',
        HomeType.operation =>
          'Làm quen với các phép so sánh, quan hệ lớn - nhỏ',
        HomeType.math => 'Chinh phục thử thách tính toán mỗi ngày!',
        // TODO: Handle this case.
        HomeType.evenOdd => "Phân biệt các số chẵn lẻ trong phạm vi 100",
        // TODO: Handle this case.
        HomeType.countShape => "Đếm các hình vuông, chữ nhật, tam giác",
      };

  //for alignment
  bool get leftAlign => switch (this) {
        HomeType.number => true,
        HomeType.operation => true,
        HomeType.math => true,
        // TODO: Handle this case.
        HomeType.evenOdd => true,
        // TODO: Handle this case.
        HomeType.countShape => true,
      };
  Color get titleColor => switch (this) {
        HomeType.number =>
          const Color(0xFF004AAD), // Xanh dương đậm (hợp với nền cam)
        HomeType.operation =>
          const Color(0xFFE63946), // Đỏ rực (hợp với nền xanh lá)
        HomeType.math => const Color(0xFF5A189A), // Tím đậm (hợp với nền vàng)
        // TODO: Handle this case.
        HomeType.evenOdd => const Color(0xFFE63946),
        // TODO: Handle this case.
        HomeType.countShape => const Color(0xFFE63946),
      };
  //for alignment
  Color get color => switch (this) {
        HomeType.number => ColorBase.accent3,
        HomeType.operation => ColorBase.accent4,
        HomeType.math => ColorBase.accent1,
        // TODO: Handle this case.
        HomeType.evenOdd => ColorBase.accent2,
        // TODO: Handle this case.
        HomeType.countShape => ColorBase.accent5,
      };
  Color get colorB => switch (this) {
        HomeType.number => ColorBase.accent3B,
        HomeType.operation => ColorBase.accent4B,
        HomeType.math => ColorBase.accent1B,
        // TODO: Handle this case.
        HomeType.evenOdd => ColorBase.accent2B,
        // TODO: Handle this case.
        HomeType.countShape => ColorBase.accent5,
      };
  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.number => EdgeInsets.zero,
        HomeType.operation => EdgeInsets.zero,
        HomeType.math => EdgeInsets.zero,
        // TODO: Handle this case.
        HomeType.evenOdd => EdgeInsets.zero,
        // TODO: Handle this case.
        HomeType.countShape => EdgeInsets.zero,
      };
  IconData get icon => switch (this) {
        HomeType.number => FontAwesomeIcons.listNumeric, // Học số (số tăng dần)
        HomeType.operation =>
          FontAwesomeIcons.greaterThanEqual, // So sánh số (lớn hơn, nhỏ hơn)
        HomeType.math => FontAwesomeIcons.plusMinus, // Icon máy tính
        // TODO: Handle this case.
        HomeType.evenOdd => FontAwesomeIcons.plusMinus,
        // TODO: Handle this case.
        HomeType.countShape => FontAwesomeIcons.plusMinus,
      };
  // Color get iconColor => switch (this) {
  //       HomeType.number => const Color(0xFFFF6F61), // Đỏ cam
  //       HomeType.operation => const Color(0xFF2EB872), // Xanh lá sáng
  //       HomeType.math => const Color(0xFFFCB900), // Vàng sáng
  //   // TODO: Handle this case.
  //   HomeType.evenOdd => null,
  //   // TODO: Handle this case.
  //   HomeType.countShape => null,
  //     };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      HomeType.number => () => Get.to(() => const NumsScreen()),
      HomeType.operation => () => Get.to(() => const CompareMainScreen()),
      HomeType.math => () => Get.to(() => const MathFeature()),
      HomeType.evenOdd => () => Navigator.push(
            getContext,
            MaterialPageRoute(
              builder: (context) => EvenOddGameSelectMode(),
            ),
          ),
      HomeType.countShape => () => Navigator.push(
            getContext,
            MaterialPageRoute(
              builder: (context) => CountShapeGameSelectMode(),
            ),
          ),
    };
  }
}
