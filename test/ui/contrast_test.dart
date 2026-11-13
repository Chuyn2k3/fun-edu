import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:funedu/ui/theme/depth.dart';

void main() {
  test('palette meets WCAG AA text contrast', () {
    expect(contrastRatio(Colors.white, AppColors.primary),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.text, AppColors.background),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.primary, AppColors.card),
        greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.textMuted, AppColors.card),
        greaterThanOrEqualTo(4.5));
  });

  test('contrastRatio follows WCAG formula', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  test('text stays readable on every raised card gradient end', () {
    final tints = [
      for (final s in Subject.values) s.tint,
      AppDepth.neutralTint
    ];
    for (final tint in tints) {
      final bottom = Color.lerp(AppColors.card, tint, 0.9)!;
      expect(contrastRatio(AppColors.textMuted, bottom),
          greaterThanOrEqualTo(4.5));
      expect(contrastRatio(AppColors.text, bottom), greaterThanOrEqualTo(4.5));
    }
  });
}
