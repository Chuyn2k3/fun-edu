// Port of lib/stroke/grader.dart. Same rules, same order, same numbers.
import { centroid, distance, maxDistance, meanDistance, pathLength, resample } from './geometry';
import type { Glyph, Stroke } from './glyph';

export type StrokeError = 'tooShort' | 'wrongDirection' | 'offPath' | 'wrongOrder';
export type StrokeResult = { ok: boolean; error?: StrokeError; deviation: number };

export type GradeConfig = {
  samples: number;
  tolerance: number;
  directionRatio: number;
  minLengthRatio: number;
  maxPointDistance: number;
  dotRadius: number;
  dotLength: number;
  shortStrokeLength: number;
  endpointTolerance: number | null;
};

export const DEFAULT_CONFIG: GradeConfig = {
  samples: 32,
  tolerance: 0.12,
  directionRatio: 0.6,
  minLengthRatio: 0.6,
  maxPointDistance: 0.25,
  dotRadius: 0.1,
  dotLength: 0.02,
  shortStrokeLength: 0,
  endpointTolerance: null,
};

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);

/** GradeConfig.forGlyph: tolerances scaled to a ruled glyph's height. */
export function gradeConfigFor(glyph: Glyph, base: GradeConfig = DEFAULT_CONFIG): GradeConfig {
  const r = glyph.ruling;
  if (!r) return base;
  let lo = Infinity;
  let hi = -Infinity;
  for (const s of glyph.strokes) {
    for (const p of s) {
      if (p.y < lo) lo = p.y;
      if (p.y > hi) hi = p.y;
    }
  }
  const height = hi > lo ? (hi - lo) / r.windowSide : 0;
  const short = (2.5 * r.cell) / r.windowSide;
  const mark = glyph.strokes.every((s) => pathLength(s) < short);
  const f = clamp(height / 0.8, mark ? 0.7 : 0.5, 1);
  return {
    ...base,
    tolerance: base.tolerance * f,
    maxPointDistance: base.maxPointDistance * f,
    shortStrokeLength: short,
    endpointTolerance: mark ? base.tolerance : null,
  };
}

export function gradeStroke(
  drawn: Stroke,
  reference: Stroke,
  config: GradeConfig = DEFAULT_CONFIG,
): StrokeResult {
  const d = drawn;
  const r = reference;
  if (r.length === 0) throw new Error('reference stroke must not be empty');
  if (d.length === 0) return { ok: false, error: 'tooShort', deviation: 0 };

  // Fail closed on NaN/infinite input.
  if (d.some((p) => !Number.isFinite(p.x) || !Number.isFinite(p.y))) {
    return { ok: false, error: 'offPath', deviation: Infinity };
  }

  const refLen = pathLength(r);

  // Rule 1: dot reference.
  if (r.length === 1 || refLen < config.dotLength) {
    const dev = distance(centroid(d), centroid(r));
    return dev <= config.dotRadius
      ? { ok: true, deviation: dev }
      : { ok: false, error: 'offPath', deviation: dev };
  }

  const rs = resample(r, config.samples);
  const fwdPts = resample(d, config.samples);
  const fwd = meanDistance(fwdPts, rs);

  // Rule 2: too short.
  if (!(pathLength(d) >= config.minLengthRatio * refLen)) {
    return { ok: false, error: 'tooShort', deviation: fwd };
  }

  // Rules 3-4: direction.
  const rev = meanDistance(resample([...d].reverse(), config.samples), rs);
  if (rev < fwd * config.directionRatio && rev <= config.tolerance) {
    return { ok: false, error: 'wrongDirection', deviation: fwd };
  }

  // Rule 5: off path.
  if (!(fwd <= config.tolerance) || !(maxDistance(fwdPts, rs) <= config.maxPointDistance)) {
    return { ok: false, error: 'offPath', deviation: fwd };
  }

  // Rule 6: short strokes start and end where the reference does.
  const endTol = config.endpointTolerance ?? config.tolerance;
  if (
    refLen < config.shortStrokeLength &&
    (!(distance(d[0], r[0]) <= endTol) || !(distance(d[d.length - 1], r[r.length - 1]) <= endTol))
  ) {
    return {
      ok: false,
      error: refLen - pathLength(d) > endTol ? 'tooShort' : 'offPath',
      deviation: fwd,
    };
  }

  return { ok: true, deviation: fwd };
}
