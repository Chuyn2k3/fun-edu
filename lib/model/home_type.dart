import 'package:flutter/material.dart';
import 'package:fun_edu/feature/math_feature/index.dart';
import 'package:fun_edu/feature/number_feature/nums_screen.dart';
import 'package:get/get.dart';

enum HomeType { number, operation, math }

extension MyHomeType on HomeType {
  //title
  String get title => switch (this) {
        HomeType.number => 'CHỮ SỐ',
        HomeType.operation => 'DẤU TOÁN',
        HomeType.math => 'PHÉP TÍNH ',
      };

  //lottie
  String get image => switch (this) {
        HomeType.number => 'education_number.png',
        HomeType.operation => 'maths_symbol.png',
        HomeType.math => 'math_pratice.png',
      };

  String get desc => switch (this) {
        HomeType.number => 'Học các chữ số từ 0 đến 9',
        HomeType.operation => 'Học các dấu cộng trừ, so sánh <, >, =',
        HomeType.math => 'Luyện tập các phép toán cộng trừ',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        HomeType.number => true,
        HomeType.operation => true,
        HomeType.math => true,
      };

  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.number => EdgeInsets.zero,
        HomeType.operation => EdgeInsets.zero,
        HomeType.math => EdgeInsets.zero,
      };

  //for navigation
  VoidCallback get onTap => switch (this) {
        HomeType.number => () => Get.to(() => const NumsScreen()),
        HomeType.operation => () => Get.to(() {}),
        HomeType.math => () => Get.to(() {}),
      };
}
