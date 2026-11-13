import 'package:flutter/material.dart';

/// Brand palette (spec 8.2a).
abstract final class AppColors {
  static const primary = Color(0xFFC8460F);
  static const accent = Color(0xFFE8590C);
  static const background = Color(0xFFFBF5EC);
  static const dot = Color(0xFFEADFCF);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF22284A);
  static const textMuted = Color(0xFF5B6385);
}

enum Subject {
  viet(Color(0xFFE8590C), Color(0xFFFFF0E4)),
  tiengViet(Color(0xFF7C3AED), Color(0xFFF3EDFF)),
  toan(Color(0xFF2563EB), Color(0xFFE8F1FF)),
  tiengAnh(Color(0xFF0F8A5F), Color(0xFFE5F7EF));

  const Subject(this.color, this.tint);

  /// Strong subject color (rings, icons).
  final Color color;

  /// Soft background tint for the subject.
  final Color tint;
}

abstract final class AppRadii {
  static const card = 28.0;
  static const tile = 18.0;
  static const pill = 999.0;
}
