import 'package:flutter/material.dart';
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
        HomeType.operation => 'DẤU TOÁN',
        HomeType.math => 'PHÉP TÍNH',
      };

  //lottie
  String get image => switch (this) {
        HomeType.number => 'education_number.png',
        HomeType.operation => 'maths_symbol.png',
        HomeType.math => 'math_pratice.png',
      };

  String get desc => switch (this) {
        HomeType.number =>
          '🦕 Học số thật vui! Khám phá từ 0 đến 9, bay cao nào! 🚀',
        HomeType.operation =>
          '🧐 So sánh thật hay! Số nào lớn hơn, nhỏ hơn hay bằng nhau? ⭐️',
        HomeType.math =>
          '🧸 Cộng trừ siêu thú vị! Tính toán vui nhộn, giỏi hơn mỗi ngày! ✨',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        HomeType.number => true,
        HomeType.operation => true,
        HomeType.math => true,
      };

  //for alignment
  Color get color => switch (this) {
        HomeType.number => Colors.green,
        HomeType.operation => Colors.blue,
        HomeType.math => Colors.red,
      };

  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.number => EdgeInsets.zero,
        HomeType.operation => EdgeInsets.zero,
        HomeType.math => EdgeInsets.zero,
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
