import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';
import { GlyphSession } from '../src/stroke/session';
import { gradeConfigFor, type StrokeResult } from '../src/stroke/grader';
import { inWindow, parseGlyph, type Stroke } from '../src/stroke/glyph';

type Num = number | 'NaN' | 'Infinity';
type Fixture = {
  glyph: string;
  tolerance: number;
  maxPointDistance: number;
  cases: {
    name: string;
    inputs: [Num, Num][][];
    results: { ok: boolean; error: string | null; deviation: Num }[];
    complete: boolean;
  }[];
};

const num = (v: Num) => (v === 'NaN' ? NaN : v === 'Infinity' ? Infinity : v);
const fixtures: Fixture[] = JSON.parse(
  readFileSync(join(__dirname, 'fixtures/grading.json'), 'utf8'),
);
const glyph = (id: string) =>
  inWindow(parseGlyph(JSON.parse(readFileSync(join(__dirname, '../../assets/glyphs', `${id}.json`), 'utf8'))));

describe('grading matches the app', () => {
  for (const f of fixtures) {
    it(`${f.glyph}: config`, () => {
      const cfg = gradeConfigFor(glyph(f.glyph));
      expect(cfg.tolerance).toBeCloseTo(f.tolerance, 12);
      expect(cfg.maxPointDistance).toBeCloseTo(f.maxPointDistance, 12);
    });
    for (const c of f.cases) {
      it(`${f.glyph}: ${c.name}`, () => {
        const session = new GlyphSession(glyph(f.glyph));
        const got: StrokeResult[] = [];
        for (const input of c.inputs) {
          if (session.isComplete) break;
          const stroke: Stroke = input.map(([x, y]) => ({ x: num(x), y: num(y) }));
          got.push(session.submit(stroke));
        }
        expect(got.length).toBe(c.results.length);
        c.results.forEach((want, i) => {
          expect(got[i].ok).toBe(want.ok);
          expect(got[i].error ?? null).toBe(want.error);
          const d = num(want.deviation);
          if (Number.isFinite(d)) expect(got[i].deviation).toBeCloseTo(d, 9);
          else expect(got[i].deviation).toBe(d);
        });
        expect(session.isComplete).toBe(c.complete);
      });
    }
  }
});
