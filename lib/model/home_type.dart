import 'package:flutter/material.dart';
import 'package:fun_edu/data/color/color.dart';
import 'package:fun_edu/router/go_router_name_enum.dart';
import 'package:fun_edu/utils/navigation_service.dart';
import 'package:go_router/go_router.dart';

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

  //image
  String get image => switch (this) {
        HomeType.number => 'numbers.png',
        HomeType.operation => 'equal-to-or-greater-than-symbol.png',
        HomeType.math => 'math.png',
        HomeType.evenOdd => 'odd.png',
        HomeType.countShape => 'shapes.png',
      };

  String get desc => switch (this) {
        HomeType.number => 'Làm quen với các số từ 0 đến 9',
        HomeType.operation =>
          'Làm quen với các phép so sánh, quan hệ lớn - nhỏ',
        HomeType.math => 'Chinh phục thử thách tính toán mỗi ngày!',
        HomeType.evenOdd => "Phân biệt các số chẵn lẻ trong phạm vi 100",
        HomeType.countShape => "Đếm các hình vuông, chữ nhật, tam giác",
      };

  Color get titleColor => switch (this) {
        HomeType.number =>
          const Color(0xFF004AAD), // Xanh dương đậm (hợp với nền cam)
        HomeType.operation =>
          const Color(0xFFE63946), // Đỏ rực (hợp với nền xanh lá)
        HomeType.math => const Color(0xFF5A189A), // Tím đậm (hợp với nền vàng)
        HomeType.evenOdd => const Color(0xFFE63946),
        HomeType.countShape => const Color(0xFFE63946),
      };
  //for alignment
  Color get color => switch (this) {
        HomeType.number => ColorBase.accent3,
        HomeType.operation => ColorBase.accent4,
        HomeType.math => ColorBase.accent1,
        HomeType.evenOdd => ColorBase.accent2,
        HomeType.countShape => ColorBase.accent5,
      };
  Color get colorB => switch (this) {
        HomeType.number => ColorBase.accent3B,
        HomeType.operation => ColorBase.accent4B,
        HomeType.math => ColorBase.accent1B,
        HomeType.evenOdd => ColorBase.accent2B,
        HomeType.countShape => ColorBase.accent5,
      };
  //for padding
  EdgeInsets get padding => switch (this) {
        HomeType.number => EdgeInsets.zero,
        HomeType.operation => EdgeInsets.zero,
        HomeType.math => EdgeInsets.zero,
        HomeType.evenOdd => EdgeInsets.zero,
        HomeType.countShape => EdgeInsets.zero,
      };

  //for navigation
  VoidCallback get onTap {
    return switch (this) {
      HomeType.number => () =>
          getContext.pushNamed(GoRouterName.numberStudy.routeName),
      HomeType.operation => () =>
          getContext.pushNamed(GoRouterName.operationStudy.routeName),
      HomeType.math => () =>
          getContext.pushNamed(GoRouterName.mathStudy.routeName),
      HomeType.evenOdd => () =>
          getContext.pushNamed(GoRouterName.evenOdd.routeName),
      HomeType.countShape => () =>
          getContext.pushNamed(GoRouterName.countShape.routeName),
    };
  }
}
