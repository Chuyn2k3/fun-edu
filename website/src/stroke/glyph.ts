// Port of lib/stroke/glyph.dart (only what the website needs).
import type { Point } from './geometry';

export type Stroke = Point[];

export type Ruling = {
  cell: number;
  baseline: number;
  windowX: number;
  windowY: number;
  windowSide: number;
};

export type Glyph = {
  id: string;
  label: string;
  speech?: string;
  strokes: Stroke[];
  ruling?: Ruling;
};

type GlyphJson = {
  id: string;
  label: string;
  speech?: string;
  ruling?: { cell: number; baseline: number; window: [number, number, number] };
  strokes: { points: [number, number][] }[];
};

export function parseGlyph(json: GlyphJson): Glyph {
  return {
    id: json.id,
    label: json.label,
    speech: json.speech,
    ruling: json.ruling && {
      cell: json.ruling.cell,
      baseline: json.ruling.baseline,
      windowX: json.ruling.window[0],
      windowY: json.ruling.window[1],
      windowSide: json.ruling.window[2],
    },
    strokes: json.strokes.map((s) => s.points.map(([x, y]) => ({ x, y }))),
  };
}

export const spokenName = (g: Glyph) => g.speech ?? g.label;

/** The glyph in its writing window's own unit square (Glyph.inWindow). */
export function inWindow(g: Glyph): Glyph {
  const r = g.ruling;
  if (!r) return g;
  const side = r.windowSide;
  return {
    ...g,
    ruling: {
      cell: r.cell / side,
      baseline: (r.baseline - r.windowY) / side,
      windowX: 0,
      windowY: 0,
      windowSide: 1,
    },
    strokes: g.strokes.map((s) =>
      s.map((p) => ({ x: (p.x - r.windowX) / side, y: (p.y - r.windowY) / side })),
    ),
  };
}
