import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:funedu/game/scene/particle_pool.dart';
import 'package:funedu/ui/theme/tokens.dart';

void main() {
  test('pool never exceeds capacity and reuses particles', () {
    final pool = ParticlePool(120);
    expect(pool.allocations, 120);
    expect(pool.alive, 0);

    // Spawn 500 particles: only 120 fit, the rest return false without growing allocations.
    var accepted = 0;
    var rejected = 0;
    for (var i = 0; i < 500; i++) {
      final ok = pool.spawn(
        x: i.toDouble(),
        y: 10,
        vx: 15,
        vy: 20,
        size: 8,
        color: GameColors.star,
        life: const Duration(milliseconds: 500),
      );
      if (ok) {
        accepted++;
      } else {
        rejected++;
      }
      expect(pool.alive, lessThanOrEqualTo(120));
      expect(pool.allocations, 120);
    }

    expect(accepted, 120);
    expect(rejected, 380);
    expect(pool.alive, 120);
    expect(pool.allocations, 120);

    // Advance partway: still alive, paint executes cleanly without allocating.
    pool.update(const Duration(milliseconds: 250));
    expect(pool.alive, 120);
    expect(pool.allocations, 120);

    final rec = ui.PictureRecorder();
    pool.paint(Canvas(rec));
    rec.endRecording().dispose();

    // Advance past lifetime: all 120 expire and return to pool for reuse.
    pool.update(const Duration(milliseconds: 300));
    expect(pool.alive, 0);
    expect(pool.allocations, 120);

    // Re-spawning reuses existing Particle instances (allocations still 120).
    for (var i = 0; i < 60; i++) {
      expect(
        pool.spawn(
          x: 50,
          y: 50,
          shape: ParticleShape.star,
          life: const Duration(milliseconds: 400),
        ),
        isTrue,
      );
    }
    expect(pool.alive, 60);
    expect(pool.allocations, 120);
  });
}
