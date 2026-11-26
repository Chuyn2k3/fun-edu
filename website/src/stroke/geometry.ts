// TypeScript port of lib/stroke/geometry.dart. Keep the arithmetic in the
// same order: the website must grade exactly like the app
// (test/grading.test.ts checks it against fixtures written by Dart).

export type Point = { x: number; y: number };

const dist = (a: Point, b: Point) => {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
};

export function pathLength(pts: Point[]): number {
  let total = 0;
  for (let i = 1; i < pts.length; i++) total += dist(pts[i - 1], pts[i]);
  return total;
}

const clamp = (v: number, lo: number, hi: number) => Math.min(Math.max(v, lo), hi);

export function resample(pts: Point[], n: number): Point[] {
  if (pts.length === 0) throw new Error('pts must not be empty');
  if (n < 1) throw new Error('n must be >= 1');
  const total = pathLength(pts);
  if (total === 0 || n === 1) return Array.from({ length: n }, () => pts[0]);

  const step = total / (n - 1);
  const out: Point[] = [pts[0]];
  let seg = 1;
  let segStart = 0;
  for (let i = 1; i < n - 1; i++) {
    const target = step * i;
    while (seg < pts.length - 1 && segStart + dist(pts[seg - 1], pts[seg]) < target) {
      segStart += dist(pts[seg - 1], pts[seg]);
      seg++;
    }
    const a = pts[seg - 1];
    const b = pts[seg];
    const len = dist(a, b);
    const t = len === 0 ? 0 : clamp((target - segStart) / len, 0, 1);
    out.push({ x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t });
  }
  out.push(pts[pts.length - 1]);
  return out;
}

function checkPaired(a: Point[], b: Point[]) {
  if (a.length !== b.length || a.length === 0) {
    throw new Error('lists must be non-empty and of equal length');
  }
}

export function meanDistance(a: Point[], b: Point[]): number {
  checkPaired(a, b);
  let sum = 0;
  for (let i = 0; i < a.length; i++) sum += dist(a[i], b[i]);
  return sum / a.length;
}

export function maxDistance(a: Point[], b: Point[]): number {
  checkPaired(a, b);
  let m = 0;
  for (let i = 0; i < a.length; i++) m = Math.max(m, dist(a[i], b[i]));
  return m;
}

export function centroid(pts: Point[]): Point {
  if (pts.length === 0) throw new Error('pts must not be empty');
  let sx = 0;
  let sy = 0;
  for (const p of pts) {
    sx += p.x;
    sy += p.y;
  }
  return { x: sx / pts.length, y: sy / pts.length };
}

export const distance = dist;

/** The pad's clamp of a touch to the unit square (trace_pad.dart). */
export const clampPoint = (p: Point): Point => ({ x: clamp(p.x, 0, 1), y: clamp(p.y, 0, 1) });
