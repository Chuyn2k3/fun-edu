import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/space_track.dart';

void main() {
  for (final size in const [Size(390, 480), Size(683, 1024), Size(1024, 700)]) {
    group('$size', () {
      final g = TrackGeometry(size);

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

      test('step 10 reaches the planet; rockets shrink with distance', () {
        for (final lane in [0, 1]) {
          expect(g.rocketRect(1, lane, 1.6).overlaps(g.planetRect), isTrue);
          expect(g.rocketWidth(1), lessThan(g.rocketWidth(0)));
        }
      });

      test('lanes stay on the track and kid lane is left of Chip lane', () {
        for (var s = 0; s <= 10; s++) {
          final a = g.basePoint(s / 10, 0);
          final b = g.basePoint(s / 10, 1);
          expect(a.dx, lessThan(b.dx));
          final half = g.widthAt(a.dy) / 2;
          expect(a.dx, greaterThan(g.cx - half));
          expect(b.dx, lessThan(g.cx + half));
        }
      });

      test('everything fits inside the scene', () {
        expect(g.planetRect.top, greaterThanOrEqualTo(0));
        expect(g.bottomW, lessThanOrEqualTo(size.width));
      });
    });
  }
}
