import { describe, expect, it } from 'vitest';
import { makeRound, LETTER_GROUPS } from '../src/quiz/generate';

const seeded = (seed: number) => () => {
  seed = (seed * 1664525 + 1013904223) % 4294967296;
  return seed / 4294967296;
};

describe('quiz rounds', () => {
  it('five valid questions', () => {
    for (let s = 1; s < 30; s++) {
      const qs = makeRound(seeded(s), { voice: true });
      expect(qs.length).toBe(5);
      for (const q of qs) {
        expect(q.choices.length).toBe(3);
        expect(new Set(q.choices).size).toBe(3);
        expect(q.correct).toBeGreaterThanOrEqual(0);
        expect(q.correct).toBeLessThanOrEqual(2);
        if (q.kind === 'count') {
          expect(q.stars).toBeGreaterThanOrEqual(1);
          expect(q.stars).toBeLessThanOrEqual(5);
          expect(q.choices[q.correct]).toBe(String(q.stars));
        }
        if (q.kind === 'add') {
          expect(q.a! + q.b!).toBeLessThanOrEqual(5);
          expect(q.choices[q.correct]).toBe(String(q.a! + q.b!));
          expect(q.prompt).toBe(`${q.a} + ${q.b} = ?`);
        }
        if (q.kind === 'letter') {
          expect(LETTER_GROUPS.some((g) => g.includes(q.choices[q.correct]))).toBe(true);
          expect(q.speech).toBe(`Chíp đọc chữ nào? ${q.letterSpeech}`);
        }
      }
    }
  });

  it('no letter question without a Vietnamese voice', () => {
    for (let s = 1; s < 30; s++) {
      expect(makeRound(seeded(s), { voice: false }).some((q) => q.kind === 'letter')).toBe(false);
    }
  });

  it('letter questions show up with a voice', () => {
    let seen = 0;
    for (let s = 1; s < 21; s++) {
      seen += makeRound(seeded(s), { voice: true }).filter((q) => q.kind === 'letter').length;
    }
    expect(seen).toBeGreaterThan(0);
  });
});
