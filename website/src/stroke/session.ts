// Port of lib/stroke/glyph_session.dart.
import type { Glyph, Stroke } from './glyph';
import { gradeConfigFor, gradeStroke, type GradeConfig, type StrokeResult } from './grader';

export class GlyphSession {
  readonly config: GradeConfig;
  private index = 0;
  readonly history: StrokeResult[] = [];

  constructor(readonly glyph: Glyph) {
    this.config = gradeConfigFor(glyph);
  }

  get currentIndex(): number {
    return this.index;
  }

  get isComplete(): boolean {
    return this.index >= this.glyph.strokes.length;
  }

  submit(drawn: Stroke): StrokeResult {
    if (this.isComplete) throw new Error('Glyph is already complete');
    let result = gradeStroke(drawn, this.glyph.strokes[this.index], this.config);
    if (result.ok) {
      this.index++;
    } else {
      // A stroke that matches a later stroke was drawn out of order.
      for (let j = this.index + 1; j < this.glyph.strokes.length; j++) {
        const later = gradeStroke(drawn, this.glyph.strokes[j], this.config);
        if (later.ok || later.error === 'wrongDirection') {
          result = { ok: false, error: 'wrongOrder', deviation: result.deviation };
          break;
        }
      }
    }
    this.history.push(result);
    return result;
  }

  reset(): void {
    this.index = 0;
    this.history.length = 0;
  }
}
