import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../ui/theme/tokens.dart';

/// Colours of one flame. The outer layer is a radial gradient
/// [outerHot] → [outer] → [outerMid] → [outerEnd] (fading to transparent).
@immutable
class FlamePalette {
  const FlamePalette({
    required this.core,
    required this.mid,
    required this.outerHot,
    required this.outer,
    required this.outerMid,
    required this.outerEnd,
    required this.glow,
    required this.smoke,
  });

  final Color core;
  final Color mid;
  final Color outerHot;
  final Color outer;
  final Color outerMid;
  final Color outerEnd;
  final Color glow;
  final Color smoke;

  static const classic = FlamePalette(
    core: GameColors.flameCore,
    mid: GameColors.flameMid,
    outerHot: GameColors.flameOuterHot,
    outer: GameColors.flameOuter,
    outerMid: GameColors.flameOuterMid,
    outerEnd: GameColors.flameOuterEnd,
    glow: GameColors.flameGlow,
    smoke: GameColors.smoke,
  );

  static const blue = FlamePalette(
    core: GameColors.blueCore,
    mid: GameColors.blueMid,
    outerHot: GameColors.blueOuterHot,
    outer: GameColors.blueOuter,
    outerMid: GameColors.blueOuterMid,
    outerEnd: GameColors.blueOuterEnd,
    glow: GameColors.blueGlow,
    smoke: GameColors.blueSmoke,
  );
}

/// What a trail leaves behind the flame.
enum ParticleKind { puff, rainbowPuff, sparkle }

/// Trail items from the rocket garage. All are drawn in code.
enum TrailStyle {
  flame('trail_flame', FlamePalette.classic, ParticleKind.puff),
  rainbow('trail_rainbow', FlamePalette.classic, ParticleKind.rainbowPuff),
  sparkle('trail_sparkle', FlamePalette.classic, ParticleKind.sparkle),
  blueFlame('trail_blue_flame', FlamePalette.blue, ParticleKind.puff);

  const TrailStyle(this.id, this.palette, this.particles);

  final String id;
  final FlamePalette palette;
  final ParticleKind particles;

  /// Unknown or missing ids fall back to the default flame.
  static TrailStyle fromId(String id) {
    for (final s in values) {
      if (s.id == id) return s;
    }
    return flame;
  }
}
