import { beforeAll, describe, expect, it } from 'vitest';
import { TracePad } from '../src/trace/pad';
import type { Glyph, Stroke } from '../src/stroke/glyph';

const glyph: Glyph = {
  id: 'so-1',
  label: 'Số 1',
  strokes: [
    [{ x: 0.2, y: 0.2 }, { x: 0.8, y: 0.2 }],
    [{ x: 0.5, y: 0.2 }, { x: 0.5, y: 0.9 }],
  ],
};

beforeAll(() => {
  // jsdom has no 2D canvas: the pad just skips drawing.
  HTMLCanvasElement.prototype.getContext = (() => null) as never;
});

function setup(size = 200) {
  const canvas = document.createElement('canvas');
  canvas.getBoundingClientRect = () =>
    ({ left: 10, top: 20, width: size, height: size, right: 10 + size, bottom: 20 + size, x: 10, y: 20, toJSON() {} }) as DOMRect;
  canvas.setPointerCapture = () => {};
  document.body.append(canvas);
  const strokes: Stroke[] = [];
  const pad = new TracePad(canvas, (s) => strokes.push(s));
  pad.setGlyph(glyph, 0);
  return { canvas, pad, strokes };
}

function fire(el: Element, type: string, x: number, y: number, pointerId = 1, isPrimary = true) {
  const e = new MouseEvent(type, { clientX: x, clientY: y, bubbles: true, cancelable: true });
  Object.defineProperty(e, 'pointerId', { value: pointerId });
  Object.defineProperty(e, 'isPrimary', { value: isPrimary });
  el.dispatchEvent(e);
}

describe('TracePad', () => {
  it('sends one stroke in unit coordinates, clamped to the square', () => {
    const { canvas, strokes } = setup();
    fire(canvas, 'pointerdown', 10, 20);
    fire(canvas, 'pointermove', 110, 120);
    fire(canvas, 'pointermove', 400, 120);
    fire(canvas, 'pointerup', 400, 120);
    expect(strokes.length).toBe(1);
    expect(strokes[0][0]).toEqual({ x: 0, y: 0 });
    expect(strokes[0][1]).toEqual({ x: 0.5, y: 0.5 });
    expect(strokes[0][2]).toEqual({ x: 1, y: 0.5 });
  });

  it('ignores a second finger while drawing', () => {
    const { canvas, strokes } = setup();
    fire(canvas, 'pointerdown', 10, 20, 1);
    fire(canvas, 'pointerdown', 150, 150, 2, false);
    fire(canvas, 'pointermove', 160, 160, 2, false);
    fire(canvas, 'pointermove', 60, 70, 1);
    fire(canvas, 'pointerup', 160, 160, 2, false);
    fire(canvas, 'pointerup', 60, 70, 1);
    expect(strokes.length).toBe(1);
    // down + one move of the first finger; the second finger adds nothing.
    expect(strokes[0].length).toBe(2);
  });

  it('keeps progress when the pad is resized', () => {
    const { pad } = setup();
    pad.setGlyph(glyph, 1);
    pad.resize();
    expect(pad.doneCount).toBe(1);
  });
});
