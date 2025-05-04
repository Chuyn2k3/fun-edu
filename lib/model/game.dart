import 'package:flutter/material.dart';

enum ShapeType {
  circle,
  square,
  triangle,
}

class GameShape {
  final ShapeType type;
  final Color color;
  final double x;
  final double y;
  final double rotation;
  final double size;

  GameShape({
    required this.type,
    required this.color,
    required this.x,
    required this.y,
    required this.rotation,
    required this.size,
  });
}

// Extension to get shape name in Vietnamese
extension ShapeTypeExtension on ShapeType {
  String get vietnameseName {
    switch (this) {
      case ShapeType.circle:
        return 'hình tròn';
      case ShapeType.square:
        return 'hình vuông';
      case ShapeType.triangle:
        return 'hình tam giác';
      default:
        return '';
    }
  }
}

// Extension to get color name in Vietnamese
extension ColorExtension on Color {
  String get vietnameseName {
    if (this == Colors.red || this.value == const Color(0xFFFF8FA2).value) {
      return 'đỏ';
    } else if (this == Colors.blue || this.value == const Color(0xFF5AC8FA).value) {
      return 'xanh dương';
    } else if (this == Colors.green || this.value == const Color(0xFF5DE0A9).value) {
      return 'xanh lá';
    } else if (this == Colors.yellow || this.value == const Color(0xFFFFD465).value) {
      return 'vàng';
    } else if (this == Colors.purple || this.value == const Color(0xFF6A5AE0).value) {
      return 'tím';
    } else {
      return '';
    }
  }
}