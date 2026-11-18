import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/race_scene.dart';
import 'package:funedu/game/scene/rocket_sprite.dart';
import 'package:funedu/game/scene/space_track.dart';
import 'package:funedu/game/scene/trails.dart';

Widget _host(Widget scene, {bool reduce = false}) => MediaQuery(
      data: MediaQueryData(
          size: const Size(390, 844), disableAnimations: reduce),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: SizedBox(width: 390, height: 480, child: scene)),
      ),
    );

RaceScene _scene(
        {int kid = 0,
        int chip = 0,
        bool boosting = false,
        bool won = false,
        int stallSeq = 0}) =>
    RaceScene(
      kidSteps: kid,
      chipSteps: chip,
      kidRocket: 'rocket_orange',
      kidTrail: 'trail_flame',
      boosting: boosting,
      won: won,
      stallSeq: stallSeq,
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

  test('anticipation dip in _Racer: baseY dips downward during first 80ms of boost when !still, not when still', () {
    final racer = Racer(
      lane: 0,
      sprite: RocketSprite.forItem('rocket_orange'),
      trail: TrailStyle.flame,
      seed: 1,
    );
    final g = TrackGeometry(const Size(390, 480));

    // Without boost, pose at t=0
    racer.pose(g, 0, still: false);
    final baseYNoBoost = racer.baseY;

    // Start boost
    racer.startBoost(hold: 0.3);

    // During first 80ms (e.g. at 40ms) when !still: baseY dips downward (baseY offset > 0)
    racer.step(0.04, leading: false);
    racer.pose(g, 0, still: false);
    expect(racer.baseY, greaterThan(baseYNoBoost));
    expect(racer.anticipationDip, closeTo(6.0, 0.01));

    // When still: true, does not dip
    racer.pose(g, 0, still: true);
    final basePtY = g.basePoint(racer.pos, racer.lane).dy;
    expect(racer.baseY, equals(basePtY));

    // After 80ms (step another 50ms -> 90ms total), dip ends
    racer.step(0.05, leading: false);
    racer.pose(g, 0, still: false);
    expect(racer.anticipationDip, 0.0);

    // snap() clears anticipation dip immediately
    racer.startBoost(hold: 0.3);
    racer.step(0.04, leading: false);
    expect(racer.anticipationDip, greaterThan(0.0));
    racer.snap();
    expect(racer.anticipationDip, 0.0);
    expect(racer.anticipationAge, double.infinity);
  });

  testWidgets('anticipation dip in RaceScene: dips during first 80ms of boost, not on reduceMotion', (tester) async {
    await tester.pumpWidget(_host(_scene()));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pump(const Duration(milliseconds: 16));

    // Trigger boost
    await tester.pumpWidget(_host(_scene(kid: 1)));
    await tester.pump(const Duration(milliseconds: 40));
    expect(state.kidAnticipationDip, greaterThan(0));

    // After 80ms, dip is finished
    await tester.pump(const Duration(milliseconds: 60));
    expect(state.kidAnticipationDip, 0.0);

    // In reduce motion, dip is never applied
    await tester.pumpWidget(_host(_scene(kid: 2), reduce: true));
    await tester.pump(const Duration(milliseconds: 40));
    expect(state.kidAnticipationDip, 0.0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('lucky stars: milestones 4 and 8 are rendered and collected when kid reaches them', (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 0)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));

    // At start: milestones 4 and 8 are rendered
    expect(state.visibleLuckyStars, [4, 8]);
    expect(state.isStarVisible(4), isTrue);
    expect(state.isStarVisible(8), isTrue);

    // Milestones 4 and 8 are positioned relative to kid on kid lane (lane 0)
    final g = TrackGeometry(const Size(390, 480));
    expect(state.luckyStarPosition(4),
        equals(g.relativeBasePoint(0.4, 0.0, 0, clampToFlight: false)));
    expect(state.luckyStarPosition(8),
        equals(g.relativeBasePoint(0.8, 0.0, 0, clampToFlight: false)));

    // At step 3: both still visible
    await tester.pumpWidget(_host(_scene(kid: 3)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.visibleLuckyStars, [4, 8]);
    expect(state.isStarVisible(4), isTrue);
    expect(state.isStarVisible(8), isTrue);

    // At step 4: star 4 is collected / disappears, star 8 remains
    await tester.pumpWidget(_host(_scene(kid: 4)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.visibleLuckyStars, [8]);
    expect(state.isStarVisible(4), isFalse);
    expect(state.isStarVisible(8), isTrue);

    // At step 7: star 8 still visible
    await tester.pumpWidget(_host(_scene(kid: 7)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.visibleLuckyStars, [8]);
    expect(state.isStarVisible(4), isFalse);
    expect(state.isStarVisible(8), isTrue);

    // At step 8: star 8 is collected / disappears
    await tester.pumpWidget(_host(_scene(kid: 8)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.visibleLuckyStars, isEmpty);
    expect(state.isStarVisible(4), isFalse);
    expect(state.isStarVisible(8), isFalse);

    // At step 10: remains collected
    await tester.pumpWidget(_host(_scene(kid: 10)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.visibleLuckyStars, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Chíp starts with leading offset, wobbles gently when overtaken',
      (tester) async {
    // When race starts (kid: 0, chip: 0), Chíp is placed ahead of Kid (lead offset)
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.chipBaseY, lessThan(state.kidBaseY));

    // When kid advances past Chíp (pump kid: 2, chip: 0): triggers turbulence wobble
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isChipWobbling, isTrue);
    expect(state.chipWobbleAngle.abs(), lessThanOrEqualTo(0.32));

    // After wobble duration (~550ms), wobble settles back to 0.0
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isChipWobbling, isFalse);
    expect(state.chipWobbleAngle, 0.0);

    // In reduceMotion mode, wobble angle is always 0.0
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0), reduce: true));
    final reduceState = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(reduceState.chipBaseY, lessThan(reduceState.kidBaseY));
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0), reduce: true));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(reduceState.chipWobbleAngle, 0.0);
    expect(reduceState.isChipWobbling, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('surge while remaining behind Chíp does not trigger wobble',
      (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 4)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isChipWobbling, isFalse);

    // Kid advances from 0 to 2, but Chíp is at 4 (Kid stays behind)
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 4)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isChipWobbling, isFalse);
    expect(state.chipWobbleAngle, 0.0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('space scrolls continuously and surges warp on boost',
      (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 1, chip: 1)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 50));
    final scrollAfterCruise = state.spaceScroll;
    expect(scrollAfterCruise, greaterThan(0));
    expect(state.spaceWarp, closeTo(0.0, 0.05));

    // Kid answers right -> warp spikes and scroll advances faster
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 1)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.spaceWarp, greaterThan(0.4));
    expect(state.spaceScroll, greaterThan(scrollAfterCruise));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Overtake banner appears when kid passes Chíp', (tester) async {
    // Start at kid: 0, chip: 0 -> expect(state.isOvertakeBannerVisible, isFalse)
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isOvertakeBannerVisible, isFalse);

    // Kid surges ahead past Chíp (kid: 2, chip: 0) -> expect(state.isOvertakeBannerVisible, isTrue)
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isOvertakeBannerVisible, isTrue);

    // After ~750ms -> expect(state.isOvertakeBannerVisible, isFalse)
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isOvertakeBannerVisible, isFalse);

    // With reduceMotion: true -> expect(state.isOvertakeBannerVisible, isFalse)
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0), reduce: true));
    final reduceState = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(reduceState.isOvertakeBannerVisible, isFalse);
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0), reduce: true));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(reduceState.isOvertakeBannerVisible, isFalse);

    // When reduceMotion is enabled mid-overtake, banner disappears immediately
    await tester.pumpWidget(_host(_scene(kid: 0, chip: 0)));
    final state2 = tester.state<RaceSceneState>(find.byType(RaceScene));
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0)));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state2.isOvertakeBannerVisible, isTrue);
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 0), reduce: true));
    expect(state2.isOvertakeBannerVisible, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('Racer overtake wobble kinematics and lead offset', () {
    final chipRacer = Racer(
      lane: 1,
      sprite: RocketSprite.chip,
      trail: TrailStyle.flame,
      seed: 2,
      isChip: true,
    );
    expect(chipRacer.leadOffset, Racer.chipLeadOffset);
    expect(chipRacer.isWobbling, isFalse);
    expect(chipRacer.wobbleAngle, 0.0);

    // Trigger turbulence wobble
    chipRacer.wobble();
    expect(chipRacer.isWobbling, isTrue);

    // Advance early in wobble: angle stays gently bounded within ±0.31 rad
    chipRacer.advance(0.06);
    expect(chipRacer.isWobbling, isTrue);
    expect(chipRacer.wobbleAngle.abs(), greaterThan(0.05));
    expect(chipRacer.wobbleAngle.abs(), lessThanOrEqualTo(0.31));

    // Advance past 0.55s duration
    chipRacer.advance(0.55);
    expect(chipRacer.isWobbling, isFalse);
    expect(chipRacer.wobbleAngle, 0.0);

    // Snap resets wobble
    chipRacer.wobble();
    expect(chipRacer.isWobbling, isTrue);
    chipRacer.snap();
    expect(chipRacer.isWobbling, isFalse);
    expect(chipRacer.wobbleAngle, 0.0);
  });

  testWidgets('wrong answer triggers kid sputter dip and smoke puff',
      (tester) async {
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 2)));
    final state = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(state.isKidStalled, isFalse);

    await tester.pumpWidget(_host(_scene(kid: 2, chip: 2, stallSeq: 1)));
    await tester.pump(const Duration(milliseconds: 16));
    expect(state.isKidStalled, isTrue);

    // Advance time ~350ms
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(state.isKidStalled, isFalse);

    // In reduceMotion mode, isKidStalled is false
    await tester.pumpWidget(_host(_scene(kid: 2, chip: 2), reduce: true));
    final reduceState = tester.state<RaceSceneState>(find.byType(RaceScene));
    expect(reduceState.isKidStalled, isFalse);
    await tester.pumpWidget(
        _host(_scene(kid: 2, chip: 2, stallSeq: 1), reduce: true));
    await tester.pump(const Duration(milliseconds: 16));
    expect(reduceState.isKidStalled, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  test('Racer stall and sputter dip kinematics', () {
    final racer = Racer(
      lane: 0,
      sprite: RocketSprite.forItem('rocket_orange'),
      trail: TrailStyle.flame,
      seed: 1,
    );
    expect(racer.isStalled, isFalse);
    expect(racer.sputterDip, 0.0);

    racer.stall();
    expect(racer.isStalled, isTrue);

    // Halfway through 350ms (~0.175s), sputter dip is at peak ~8px
    racer.advance(0.175);
    expect(racer.isStalled, isTrue);
    expect(racer.sputterDip, closeTo(8.0, 0.1));

    // Past 350ms, stall ends
    racer.advance(0.18);
    expect(racer.isStalled, isFalse);
    expect(racer.sputterDip, 0.0);

    // snap clears stall
    racer.stall();
    expect(racer.isStalled, isTrue);
    racer.snap();
    expect(racer.isStalled, isFalse);
  });
}
