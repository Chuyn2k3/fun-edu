import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/feature/digit_feature/math/index.dart';
import 'package:fun_edu/feature/digit_feature/number/digit_number.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/math_feature/screen/Quiz/quiz_screen.dart';
import 'package:fun_edu/feature/operation_feature/compare_number.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:fun_edu/feature/operation_feature/operation_page.dart';
import 'package:fun_edu/feature/operation_feature/operator_screen.dart';
import 'package:get/get.dart';

enum DigitRecogize { number, math }

extension MyDigitRecogize on DigitRecogize {
  String get title => switch (this) {
        DigitRecogize.number => 'Bé tập viết số',
        DigitRecogize.math => 'Bé giải phép tính',
      };

  String get desc => switch (this) {
        DigitRecogize.number =>
          'Nhìn số và viết lại, xem máy có đoán đúng không nhé!',
        DigitRecogize.math =>
          'Giải phép tính bằng cách viết đáp án, thật thú vị!',
      };

  String get image => switch (this) {
        DigitRecogize.number => 'tablet.png',
        DigitRecogize.math => 'handwritten.png',
      };
  //for alignment
  bool get leftAlign => switch (this) {
        DigitRecogize.number => true,
        DigitRecogize.math => true,
      };

  //for alignment
  Color get color => switch (this) {
        DigitRecogize.number => ColorBase.accent3,
        DigitRecogize.math => ColorBase.accent1,
      };
  Color get colorB => switch (this) {
        DigitRecogize.number => ColorBase.accent3B,
        DigitRecogize.math => ColorBase.accent1B,
      };
  //for padding
  EdgeInsets get padding => switch (this) {
        DigitRecogize.number => EdgeInsets.zero,
        DigitRecogize.math => EdgeInsets.zero,
      };
  IconData get icon => switch (this) {
        DigitRecogize.number =>
          FontAwesomeIcons.listNumeric, // Học số (số tăng dần)
        DigitRecogize.math => FontAwesomeIcons.plusMinus // Icon máy tính
      };
  Color get iconColor => switch (this) {
        DigitRecogize.number => const Color(0xFFFF6F61), // Đỏ cam
        DigitRecogize.math => const Color(0xFFFCB900), // Vàng sáng
      };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      DigitRecogize.number => () => Get.to(() => const DigitNumberScreen()),
      DigitRecogize.math => () => Get.to(() => const DigitMath()),
      //Get.snackbar("Thông báo", "Tính năng chưa hỗ trợ"),
    };
  }
}
