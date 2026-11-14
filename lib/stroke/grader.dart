import 'geometry.dart';
import 'glyph.dart';

enum StrokeError { tooShort, wrongDirection, offPath, wrongOrder }

class StrokeResult {
  const StrokeResult({required this.ok, this.error, required this.deviation});

  final bool ok;
  final StrokeError? error;

  /// Mean distance to the reference (distance to the dot for dot strokes).
  final double deviation;
}

class GradeConfig {
  const GradeConfig({
    this.samples = 32,
    this.tolerance = 0.12,
    this.directionRatio = 0.6,
    this.minLengthRatio = 0.6,
    this.maxPointDistance = 0.25,
    this.dotRadius = 0.1,
    this.dotLength = 0.02,
    this.shortStrokeLength = 0,
  });

  final int samples;
  final double tolerance;
  final double directionRatio;
  final double minLengthRatio;
  final double maxPointDistance;
  final double dotRadius;
  final double dotLength;

  /// Reference strokes shorter than this (and not dots) must also start and
  /// end within [tolerance] of the reference's start and end, so short tone
  /// marks and diacritics (sắc vs huyền, ă vs â) are told apart. 0 = off.
  final double shortStrokeLength;

  GradeConfig copyWith({
    double? tolerance,
    double? maxPointDistance,
    double? shortStrokeLength,
  }) =>
      GradeConfig(
        samples: samples,
        tolerance: tolerance ?? this.tolerance,
        directionRatio: directionRatio,
        minLengthRatio: minLengthRatio,
        maxPointDistance: maxPointDistance ?? this.maxPointDistance,
        dotRadius: dotRadius,
        dotLength: dotLength,
        shortStrokeLength: shortStrokeLength ?? this.shortStrokeLength,
      );

  /// This config fitted to [glyph] (design §2: small letters must not be
  /// graded looser than digits).
  ///
  /// Glyphs without a ruling (the old strokes and digits) get this config
  /// unchanged. For ruled glyphs (letters, tone marks) [tolerance] and
  /// [maxPointDistance] are scaled by `clamp(height / 0.8, 0.5, 1)`, where
  /// height is the vertical extent of all reference strokes in window units:
  /// a digit is 0.8 tall, so the tolerance stays the same fraction of the
  /// glyph's height. Strokes shorter than 2.5 ô li get the endpoint check
  /// (see [shortStrokeLength]).
  GradeConfig forGlyph(Glyph glyph) {
    final r = glyph.ruling;
    if (r == null) return this;
    var lo = double.infinity, hi = double.negativeInfinity;
    for (final s in glyph.strokes) {
      for (final p in s.points) {
        if (p.y < lo) lo = p.y;
        if (p.y > hi) hi = p.y;
      }
    }
    final height = hi > lo ? (hi - lo) / r.windowSide : 0.0;
    final f = (height / 0.8).clamp(0.5, 1.0);
    return copyWith(
      tolerance: tolerance * f,
      maxPointDistance: maxPointDistance * f,
      shortStrokeLength: 2.5 * r.cell / r.windowSide,
    );
  }
}

/// Grades one [drawn] stroke against one [reference] stroke.
StrokeResult gradeStroke(Stroke drawn, Stroke reference,
    [GradeConfig config = const GradeConfig()]) {
  final d = drawn.points;
  final r = reference.points;
  if (r.isEmpty) throw ArgumentError('reference stroke must not be empty');
  if (d.isEmpty) {
    return const StrokeResult(
        ok: false, error: StrokeError.tooShort, deviation: 0);
  }

  // Fail closed on NaN/infinite input: comparisons with NaN are all false and
  // would otherwise be accepted.
  if (d.any((p) => !p.x.isFinite || !p.y.isFinite)) {
    return const StrokeResult(
        ok: false, error: StrokeError.offPath, deviation: double.infinity);
  }

  final refLen = pathLength(r);

  // Rule 1: dot reference.
  if (r.length == 1 || refLen < config.dotLength) {
    final dev = distance(centroid(d), centroid(r));
    return dev <= config.dotRadius
        ? StrokeResult(ok: true, deviation: dev)
        : StrokeResult(ok: false, error: StrokeError.offPath, deviation: dev);
  }

  final rs = resample(r, config.samples);
  final fwdPts = resample(d, config.samples);
  final fwd = meanDistance(fwdPts, rs);

  // Rule 2: too short.
  if (!(pathLength(d) >= config.minLengthRatio * refLen)) {
    return StrokeResult(
        ok: false, error: StrokeError.tooShort, deviation: fwd);
  }

  // Rules 3-4: direction.
  final rev = meanDistance(resample(d.reversed.toList(), config.samples), rs);
  if (rev < fwd * config.directionRatio && rev <= config.tolerance) {
    return StrokeResult(
        ok: false, error: StrokeError.wrongDirection, deviation: fwd);
  }

  // Rule 5: off path.
  if (!(fwd <= config.tolerance) ||
      !(maxDistance(fwdPts, rs) <= config.maxPointDistance)) {
    return StrokeResult(ok: false, error: StrokeError.offPath, deviation: fwd);
  }

  // Rule 6: short strokes start and end where the reference does.
  if (refLen < config.shortStrokeLength &&
      (!(distance(d.first, r.first) <= config.tolerance) ||
          !(distance(d.last, r.last) <= config.tolerance))) {
    return StrokeResult(ok: false, error: StrokeError.offPath, deviation: fwd);
  }

  return StrokeResult(ok: true, deviation: fwd);
}
