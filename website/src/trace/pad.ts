// The tracing square: draws the model strokes (and ruling for letters) and
// turns one pointer's drag into a stroke in unit coordinates.
import { clampPoint, type Point } from '../stroke/geometry';
import type { Glyph, Stroke } from '../stroke/glyph';

const COLORS = {
  paper: '#ffffff',
  rule: '#eadfcf',
  ruleStrong: '#d9c6ad',
  model: '#eadfcf',
  next: '#f4b393',
  done: '#c8460f',
  ink: '#22284a',
  start: '#2e9e5b',
};

export class TracePad {
  private glyph: Glyph | null = null;
  private done = 0;
  private current: Point[] | null = null;
  private pointerId: number | null = null;
  private hint = 0;
  private hintTimer: number | null = null;
  private readonly ro: ResizeObserver | null;

  constructor(
    private readonly canvas: HTMLCanvasElement,
    private readonly onStroke: (s: Stroke) => void,
  ) {
    canvas.style.touchAction = 'none';
    canvas.addEventListener('pointerdown', this.down);
    canvas.addEventListener('pointermove', this.move);
    canvas.addEventListener('pointerup', this.up);
    canvas.addEventListener('pointercancel', this.cancel);
    this.ro = typeof ResizeObserver === 'undefined' ? null : new ResizeObserver(() => this.resize());
    this.ro?.observe(canvas);
  }

  get doneCount(): number {
    return this.done;
  }

  setGlyph(glyph: Glyph, done: number): void {
    this.glyph = glyph;
    this.done = done;
    this.current = null;
    this.pointerId = null;
    this.draw();
  }

  /** Shows the next model stroke brighter for a moment. */
  flashHint(): void {
    this.hint = 1;
    if (this.hintTimer !== null) clearTimeout(this.hintTimer);
    this.hintTimer = window.setTimeout(() => {
      this.hint = 0;
      this.draw();
    }, 900);
    this.draw();
  }

  /** Matches the backing store to the element's size (rotation, resize). */
  resize(): void {
    const rect = this.canvas.getBoundingClientRect();
    const dpr = window.devicePixelRatio || 1;
    const side = Math.max(1, Math.round(rect.width * dpr));
    if (this.canvas.width !== side) {
      this.canvas.width = side;
      this.canvas.height = side;
    }
    this.draw();
  }

  destroy(): void {
    this.ro?.disconnect();
    this.canvas.removeEventListener('pointerdown', this.down);
    this.canvas.removeEventListener('pointermove', this.move);
    this.canvas.removeEventListener('pointerup', this.up);
    this.canvas.removeEventListener('pointercancel', this.cancel);
  }

  private toUnit(e: PointerEvent): Point {
    const r = this.canvas.getBoundingClientRect();
    return clampPoint({ x: (e.clientX - r.left) / r.width, y: (e.clientY - r.top) / r.height });
  }

  private readonly down = (e: PointerEvent) => {
    if (this.pointerId !== null || e.isPrimary === false || !this.glyph) return;
    e.preventDefault();
    this.pointerId = e.pointerId;
    this.canvas.setPointerCapture?.(e.pointerId);
    this.current = [this.toUnit(e)];
    this.draw();
  };

  private readonly move = (e: PointerEvent) => {
    if (e.pointerId !== this.pointerId || !this.current) return;
    e.preventDefault();
    this.current.push(this.toUnit(e));
    this.draw();
  };

  private readonly up = (e: PointerEvent) => {
    if (e.pointerId !== this.pointerId || !this.current) return;
    const stroke = this.current;
    this.current = null;
    this.pointerId = null;
    this.draw();
    this.onStroke(stroke);
  };

  private readonly cancel = (e: PointerEvent) => {
    if (e.pointerId !== this.pointerId) return;
    this.current = null;
    this.pointerId = null;
    this.draw();
  };

  private draw(): void {
    const ctx = this.canvas.getContext?.('2d');
    const g = this.glyph;
    if (!ctx || !g) return;
    const s = this.canvas.width;
    const at = (p: Point) => [p.x * s, p.y * s] as const;
    ctx.fillStyle = COLORS.paper;
    ctx.fillRect(0, 0, s, s);

    const r = g.ruling;
    if (r) {
      // Ruled paper (ô li) like the writing screen.
      ctx.lineWidth = Math.max(1, s / 400);
      for (let y = r.baseline % r.cell; y <= 1.0001; y += r.cell) {
        ctx.strokeStyle = Math.abs(y - r.baseline) < 1e-6 ? COLORS.ruleStrong : COLORS.rule;
        ctx.beginPath();
        ctx.moveTo(0, y * s);
        ctx.lineTo(s, y * s);
        ctx.stroke();
      }
    }

    const line = (pts: Point[], color: string, width: number) => {
      if (pts.length === 0) return;
      ctx.strokeStyle = color;
      ctx.fillStyle = color;
      ctx.lineWidth = width;
      ctx.lineCap = 'round';
      ctx.lineJoin = 'round';
      if (pts.length === 1) {
        const [x, y] = at(pts[0]);
        ctx.beginPath();
        ctx.arc(x, y, width / 2, 0, Math.PI * 2);
        ctx.fill();
        return;
      }
      ctx.beginPath();
      pts.forEach((p, i) => {
        const [x, y] = at(p);
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      });
      ctx.stroke();
    };

    const w = s * 0.05;
    g.strokes.forEach((st, i) => {
      if (i < this.done) line(st, COLORS.done, w);
      else if (i === this.done) line(st, this.hint ? COLORS.done : COLORS.next, w);
      else line(st, COLORS.model, w);
    });
    const next = g.strokes[this.done];
    if (next) {
      const [x, y] = at(next[0]);
      ctx.fillStyle = COLORS.start;
      ctx.beginPath();
      ctx.arc(x, y, w * 0.7, 0, Math.PI * 2);
      ctx.fill();
    }
    if (this.current) line(this.current, COLORS.ink, w * 0.6);
  }
}
