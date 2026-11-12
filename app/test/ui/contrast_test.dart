import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/theme/contrast.dart';
import 'package:funedu/ui/theme/tokens.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('palette meets WCAG AA text contrast', () {
    expect(contrastRatio(Colors.white, AppColors.primary), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.text, AppColors.background), greaterThanOrEqualTo(4.5));
    expect(contrastRatio(AppColors.textMuted, AppColors.card), greaterThanOrEqualTo(4.5));
  });

  test('contrastRatio follows WCAG formula', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });
}
