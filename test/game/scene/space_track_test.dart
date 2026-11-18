import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/space_track.dart';

void main() {
  for (final size in const [
    Size(390, 844),
    Size(390, 480),
    Size(683, 1024),
    Size(1024, 700),
  ]) {
    group('$size', () {
      final bottomInset = size.height > 600 ? 220.0 : 0.0;
      final g = TrackGeometry(size, bottomInset: bottomInset);

      test('rocket base rises monotonically for steps 0..10', () {
        for (final lane in [0, 1]) {
          var prev = double.infinity;
          for (var s = 0; s <= 10; s++) {
            final y = g.basePoint(s / 10, lane).dy;
            expect(y, lessThan(prev), reason: 'lane $lane step $s');
            prev = y;
          }
          expect(g.basePoint(0, lane).dy, lessThan(size.height));
        }
      });

      test('free-flight rockets keep consistent readable width and zero lane tilt',
          () {
        expect(g.rocketWidth(1), equals(g.rocketWidth(0)));
        expect(g.rocketWidth(0), greaterThanOrEqualTo(62));
        expect(g.laneTilt(0), 0.0);
        expect(g.laneTilt(1), 0.0);
      });

      test('kid lane is left of Chip lane with clean separation', () {
        final a = g.laneX(0);
        final b = g.laneX(1);
        expect(a, lessThan(b));
        expect(b - a, greaterThanOrEqualTo(g.rocketW * 0.9));
      });

      test('relative chase positions place ahead racer higher on screen', () {
        final behindY = g.relativeY(0.2, 0.4);
        final tiedY = g.relativeY(0.4, 0.4);
        final aheadY = g.relativeY(0.6, 0.4);
        expect(aheadY, lessThan(tiedY));
        expect(tiedY, lessThan(behindY));
      });

      test('destination planet grows and approaches as progress climbs 0..1', () {
        final farPlanet = g.planetRectFor(0.0);
        final midPlanet = g.planetRectFor(0.5);
        final nearPlanet = g.planetRectFor(1.0);
        expect(midPlanet.width, greaterThan(farPlanet.width));
        expect(nearPlanet.width, greaterThan(midPlanet.width));
        expect(nearPlanet.center.dy, greaterThan(farPlanet.center.dy));
        expect(farPlanet.top, greaterThanOrEqualTo(0));
      });

      test('mini progress bar and overtake banner stay safely inside bounds', () {
        final bar = g.progressBarRect;
        expect(bar.right, lessThanOrEqualTo(size.width));
        expect(bar.top, greaterThanOrEqualTo(g.topSafeY));
        expect(bar.bottom, lessThanOrEqualTo(g.bottomSafeY));
        expect(g.bannerCenter.dy, lessThan(g.kidAnchorY));
      });
    });
  }

  test('SceneClock accelerates scroll speed smoothly under warp', () {
    final c = SceneClock();
    expect(c.scroll, 0);
    expect(c.warp, 0);

    c.advance(0.1, targetWarp: 0);
    final cruiseDelta = c.scroll;
    expect(cruiseDelta, greaterThan(0));

    final beforeWarp = c.scroll;
    c.advance(0.1, targetWarp: 1.0);
    c.advance(0.1, targetWarp: 1.0);
    final warpDelta = (c.scroll - beforeWarp) / 2;
    expect(c.warp, greaterThan(0.5));
    expect(warpDelta, greaterThan(cruiseDelta * 1.5));
  });
}
