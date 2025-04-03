import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/quiz_screen.dart';
import 'package:fun_edu/feature/operation_feature/compare_number.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:fun_edu/feature/operation_feature/operation_page.dart';
import 'package:fun_edu/feature/operation_feature/operator_screen.dart';
import 'package:get/get.dart';

enum HomeType { number, operation, math }

extension MyHomeType on HomeType {
  //title
  String get title => switch (this) {
        HomeType.number => 'CHỮ SỐ',
        HomeType.operation => 'PHÉP SO SÁNH',
        HomeType.math => 'PHÉP TÍNH',
      };

  //lottie
  String get image => switch (this) {
        HomeType.number => 'numbers.png',
        HomeType.operation => 'equal-to-or-greater-than-symbol.png',
        HomeType.math => 'math.png',
      };

  String get desc => switch (this) {
        HomeType.number => 'Làm quen với các số từ 0 đến 9',
        HomeType.operation =>
          'Làm quen với các phép so sánh, quan hệ lớn - nhỏ',
        HomeType.math => 'Chinh phục thử thách tính toán mỗi ngày!',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        HomeType.number => true,
        HomeType.operation => true,
        HomeType.math => true,
      };
  Color get titleColor => switch (this) {
        HomeType.number =>
          const Color(0xFF004AAD), // Xanh dương đậm (hợp với nền cam)
        HomeType.operation =>
          const Color(0xFFE63946), // Đỏ rực (hợp với nền xanh lá)
        HomeType.math => const Color(0xFF5A189A), // Tím đậm (hợp với nền vàng)
      };
  //for alignment
  Color get color => switch (this) {
        HomeType.number => ColorBase.accent3,
        HomeType.operation => ColorBase.accent4,
        HomeType.math => ColorBase.accent1,
      };
  Color get colorB => switch (this) {
        HomeType.number => ColorBase.accent3B,
        HomeType.operation => ColorBase.accent4B,
        HomeType.math => ColorBase.accent1B,
      };
  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.number => EdgeInsets.zero,
        HomeType.operation => EdgeInsets.zero,
        HomeType.math => EdgeInsets.zero,
      };
  IconData get icon => switch (this) {
        HomeType.number => FontAwesomeIcons.listNumeric, // Học số (số tăng dần)
        HomeType.operation =>
          FontAwesomeIcons.greaterThanEqual, // So sánh số (lớn hơn, nhỏ hơn)
        HomeType.math => FontAwesomeIcons.plusMinus // Icon máy tính
      };
  Color get iconColor => switch (this) {
        HomeType.number => const Color(0xFFFF6F61), // Đỏ cam
        HomeType.operation => const Color(0xFF2EB872), // Xanh lá sáng
        HomeType.math => const Color(0xFFFCB900), // Vàng sáng
      };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      HomeType.number => () => Get.to(() => const NumsScreen()),
      HomeType.operation => () => Get.to(() => const CompareMainScreen()),
      HomeType.math => () => Get.to(() => const QuizScreen()),
      //Get.snackbar("Thông báo", "Tính năng chưa hỗ trợ"),
    };
  }
}
