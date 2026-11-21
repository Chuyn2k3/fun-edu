import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/ui/transitions/smooth_page_transition.dart';

void main() {
  testWidgets(
      'buildSmoothTransitionPage builds CustomTransitionPage with 160ms fade and scale',
      (tester) async {
    await tester.pumpWidget(const SizedBox());

    const key = ValueKey('test-page');
    const child = Scaffold(body: Text('Hello Transition'));
    final page = buildSmoothTransitionPage<void>(
      key: key,
      child: child,
    ) as CustomTransitionPage<void>;

    expect(page.key, key);
    expect(page.transitionDuration, const Duration(milliseconds: 160));
    expect(page.reverseTransitionDuration, const Duration(milliseconds: 160));

    // Test transition builder
    final widget = page.transitionsBuilder(
      tester.element(find.byType(SizedBox)),
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0.0),
      child,
    );

    expect(widget, isA<FadeTransition>());
    final fade = widget as FadeTransition;
    expect(fade.child, isA<ScaleTransition>());
  });

  test('iOS keeps the system page so the edge swipe back works', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    const key = ValueKey('ios-page');
    final page = buildSmoothTransitionPage<void>(
      key: key,
      child: const SizedBox(),
    );
    expect(page, isA<CupertinoPage<void>>());
    expect(page.key, key);
  });
}
