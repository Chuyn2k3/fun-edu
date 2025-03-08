import 'package:flutter/material.dart';
import 'package:fun_edu/feature/operation_feature/add_sub_page.dart';
import 'package:fun_edu/feature/operation_feature/comparsion_page.dart';
import 'package:get/get.dart';

enum OperatorType {
  comparsion,
  addSub,
}

extension MyOperatorType on OperatorType {
  //title
  String get title => switch (this) {
        OperatorType.comparsion => 'Dấu lớn hơn(>), nhỏ hơn(<), bằng(=)',
        OperatorType.addSub => 'Dấu cộng(+), trừ(-)',
      };

  //lottie
  String get image => switch (this) {
        OperatorType.comparsion => 'greater_operation.png',
        OperatorType.addSub => 'add_sub.png',
      };

  //for alignment
  bool get leftAlign => switch (this) {
        OperatorType.comparsion => true,
        OperatorType.addSub => false,
      };

  //for padding
  EdgeInsets get padding => switch (this) {
        OperatorType.comparsion => const EdgeInsets.all(16),
        OperatorType.addSub => const EdgeInsets.all(16),
      };

  //for navigation
  VoidCallback get onTap => switch (this) {
        OperatorType.comparsion => () => Get.to(() => const ComparsionPage()),
        OperatorType.addSub => () => Get.to(() => const AddSubPage()),
      };
}
