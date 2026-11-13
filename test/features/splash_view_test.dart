import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/features/splash/splash_view.dart';
import 'package:funedu/ui/assets.dart';
import 'package:funedu/ui/theme/tokens.dart';

void main() {
  testWidgets('SplashView shows the logo and the word ChipChip', (t) async {
    await t.pumpWidget(const MaterialApp(home: SplashView()));
    expect(find.byKey(const ValueKey('splash')), findsOneWidget);
    expect(find.text('ChipChip'), findsOneWidget);
    final img = t.widget<Image>(find.byType(Image));
    expect((img.image as AssetImage).assetName, AppImages.logo);
    expect(t.getSize(find.byType(Image)), const Size(160, 160));
    final text = t.widget<Text>(find.text('ChipChip'));
    expect(text.style?.color, AppColors.primary);
    expect(text.style?.fontSize, 34);
    expect(text.style?.fontWeight, FontWeight.w900);
  });

  testWidgets('SplashView breathes between 0.96 and 1.0', (t) async {
    await t.pumpWidget(const MaterialApp(home: SplashView()));
    double scale() => t
        .widget<ScaleTransition>(find.byKey(const ValueKey('splash-logo')))
        .scale
        .value;
    expect(scale(), closeTo(0.96, 0.001));
    await t.pump(const Duration(milliseconds: 900));
    expect(scale(), closeTo(1.0, 0.001));
    await t.pump(const Duration(milliseconds: 900));
    expect(scale(), closeTo(0.96, 0.001));
  });
}
