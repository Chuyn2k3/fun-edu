import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';

Widget _host(Widget scene, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(
          size: const Size(390, 844), disableAnimations: reduce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 390, height: 480, child: scene)),
      ),
    );

RaceScene _scene(
        {int kid = 0, int chip = 0, bool boosting = false, bool won = false}) =>
    RaceScene(
      kidSteps: kid,
      chipSteps: chip,
      kidRocket: 'rocket_orange',
      kidTrail: 'trail_flame',
      boosting: boosting,
      won: won,
    );

void main() {
  testWidgets('reduce motion: flame is static and rockets jump to targets',
      (tester) async {
    await tester.pumpWidget(_host(_scene(), reduce: true));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    final t0 = state.flameTime;
    await tester.pumpWidget(_host(_scene(kid: 5, chip: 3), reduce: true));
    await tester.pump(const Duration(seconds: 2));
    expect(state.flameTime, t0);
    expect(state.kidProgress, 0.5);
    expect(state.chipProgress, 0.3);
    expect(state.isTicking, isFalse);
  });

  testWidgets('reduce motion: the winner still gets the leader flame',
      (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 9, chip: 9), reduce: true));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.kidFlameIntensity, closeTo(1.0, 1e-9));
    await tester.pumpWidget(
        _host(_scene(kid: 10, chip: 9, won: true), reduce: true));
    expect(state.kidFlameIntensity, closeTo(1.15, 1e-9));
    expect(state.chipFlameIntensity, closeTo(1.0, 1e-9));
  });

  testWidgets('a new target mid-surge keeps rising smoothly, no jump back',
      (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pumpWidget(_host(_scene(kid: 2)));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final atRetarget = state.kidProgress;
    expect(atRetarget, inExclusiveRange(0.0, 0.2));
    await tester.pumpWidget(_host(_scene(kid: 3)));
    var prev = atRetarget;
    var peak = atRetarget;
    for (var i = 0; i < 70; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final p = state.kidProgress;
      // Only the small spring overshoot may pull it back, never a jump.
      expect(p, greaterThan(prev - 0.005));
      expect(p, greaterThanOrEqualTo(atRetarget));
      if (p > peak) peak = p;
      prev = p;
    }
    expect(peak, lessThan(0.3 * 1.05));
    expect(state.kidProgress, closeTo(0.3, 0.005));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with motion the clock runs and rockets spring to targets',
      (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isTicking, isTrue);
    final t0 = state.flameTime;
    await tester.pumpWidget(_host(_scene(kid: 4, chip: 2)));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    expect(state.flameTime, greaterThan(t0));
    expect(state.kidProgress, greaterThan(0));
    expect(state.kidProgress, lessThan(0.4), reason: 'still moving');
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.kidProgress, closeTo(0.4, 0.005));
    expect(state.chipProgress, closeTo(0.2, 0.005));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a correct answer boosts the flame, then it settles',
      (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.kidBoost, 0);
    await tester.pumpWidget(_host(_scene(kid: 1)));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 80));
    expect(state.kidBoost, greaterThan(0.5));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.kidBoost, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('boosting turning true starts a comet fly-by that ends',
      (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.cometProgress, isNull);
    await tester.pumpWidget(_host(_scene(kid: 2, boosting: true)));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.cometProgress, isNotNull);
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.cometProgress, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('speed lines and micro shake activate on boost then settle',
      (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isSpeedLinesActive, isFalse);
    expect(state.shakeOffset, Offset.zero);

    await tester.pumpWidget(_host(_scene(kid: 1)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.isSpeedLinesActive, isTrue);
    expect(state.shakeOffset, isNot(Offset.zero));

    // Shake ends after 0.25s
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.shakeOffset, Offset.zero);
    expect(state.isSpeedLinesActive, isTrue);

    // Speed lines end after 0.45s
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isSpeedLinesActive, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduce motion disables speed lines and micro shake',
      (tester) async {
    await tester.pumpWidget(_host(_scene(), reduce: true));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isSpeedLinesActive, isFalse);
    expect(state.shakeOffset, Offset.zero);

    await tester.pumpWidget(_host(_scene(kid: 2, boosting: true), reduce: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.isSpeedLinesActive, isFalse);
    expect(state.shakeOffset, Offset.zero);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('scene has a Vietnamese semantics label with both positions',
      (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 6, chip: 5), reduce: true));
    expect(
        find.bySemanticsLabel(RegExp('Tên lửa của bé: 6 trên 10.*Chíp Chíp: 5 trên 10')),
        findsOneWidget);
  });

  testWidgets('renders on a tablet-sized box without exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(1366, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 683, height: 1024, child: _scene(kid: 3))));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
