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
  });

  final int samples;
  final double tolerance;
  final double directionRatio;
  final double minLengthRatio;
  final double maxPointDistance;
  final double dotRadius;
  final double dotLength;
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

  return StrokeResult(ok: true, deviation: fwd);
}
