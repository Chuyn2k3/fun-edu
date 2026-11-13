import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/layout/form_factor.dart';

void main() {
  test('formFactorOf classifies window sizes', () {
    expect(formFactorOf(const Size(390, 844)), FormFactor.phone);
    expect(formFactorOf(const Size(844, 390)), FormFactor.phone);
    expect(formFactorOf(const Size(500, 1366)), FormFactor.phone);
    expect(formFactorOf(const Size(1024, 1366)), FormFactor.tabletPortrait);
    expect(formFactorOf(const Size(1366, 1024)), FormFactor.tabletLandscape);
    expect(formFactorOf(const Size(744, 1133)), FormFactor.tabletPortrait);
  });

  testWidgets('context extension reads the window size', (tester) async {
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late FormFactor ff;
    late bool tablet;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ff = c.formFactor;
        tablet = c.isTablet;
        return const SizedBox();
      }),
    ));
    expect(ff, FormFactor.tabletLandscape);
    expect(tablet, isTrue);
  });
}
