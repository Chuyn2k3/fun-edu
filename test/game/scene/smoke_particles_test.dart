import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/smoke_particles.dart';
import 'package:funedu/game/scene/trails.dart';

void main() {
  for (final style in TrailStyle.values) {
    test('${style.name}: pool never exceeds 24 and slots are reused only at '
        'alpha 0', () {
      final pool = SmokeParticles(style: style, seed: 7);
      expect(pool.capacity, lessThanOrEqualTo(24));
      final reuseAlphas = <double>[];
      pool.onReuse = (slot, alpha) => reuseAlphas.add(alpha);
      var maxLive = 0;
      // 10 s at 60 fps, boosted half the time so the emitter wants more.
      for (var i = 0; i < 600; i++) {
        pool.update(1 / 60,
            emitX: 100, emitY: 300 - i * 0.2, unit: 1, intensity: i % 120 < 60 ? 1.8 : 1);
        maxLive = pool.liveCount > maxLive ? pool.liveCount : maxLive;
        expect(pool.liveCount, lessThanOrEqualTo(24));
        for (var s = 0; s < pool.capacity; s++) {
          final a = pool.alphaOf(s);
          expect(a, inInclusiveRange(0.0, 1.0));
        }
      }
      expect(maxLive, greaterThan(8), reason: 'the emitter does emit');
      expect(reuseAlphas, isNotEmpty, reason: 'slots get recycled');
      expect(reuseAlphas.every((a) => a == 0), isTrue);
    });
  }

  test('a particle fades smoothly to exactly 0 at the end of its life', () {
    final pool = SmokeParticles(style: TrailStyle.flame, seed: 1);
    pool.update(1 / 60, emitX: 0, emitY: 0, unit: 1, intensity: 1);
    expect(pool.liveCount, greaterThan(0));
    // Stop emitting, let everything die.
    var last = 1.0;
    for (var i = 0; i < 240; i++) {
      pool.update(1 / 60, emitX: 0, emitY: 0, unit: 1, intensity: 0);
      last = pool.alphaOf(0);
    }
    expect(pool.liveCount, 0);
    expect(last, 0);
  });

  test('clear() empties the pool', () {
    final pool = SmokeParticles(style: TrailStyle.rainbow, seed: 1);
    for (var i = 0; i < 30; i++) {
      pool.update(1 / 60, emitX: 0, emitY: 0, unit: 1, intensity: 1);
    }
    pool.clear();
    expect(pool.liveCount, 0);
  });
}
