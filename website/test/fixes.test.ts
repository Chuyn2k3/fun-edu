import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { afterEach, describe, expect, it, vi } from 'vitest';
import { quizVoiceOn } from '../src/quiz/options';
import { speak, resetSpeechForTest } from '../src/lib/speech';

const css = (f: string) => readFileSync(join(__dirname, '../src/styles', f), 'utf8');
const hex = (h: string) => [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255);
const lum = (h: string) => {
  const [r, g, b] = hex(h).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const ratio = (a: string, b: string) => {
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
};
const token = (name: string) => css('tokens.css').match(new RegExp(`--${name}:\\s*(#[0-9a-f]{6})`, 'i'))![1];

describe('review fixes', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    vi.useRealTimers();
    resetSpeechForTest();
    localStorage.clear();
  });

  it('no letter questions while sound is off', () => {
    expect(quizVoiceOn(true, true)).toBe(true);
    expect(quizVoiceOn(true, false)).toBe(false);
    expect(quizVoiceOn(false, true)).toBe(false);
  });

  it('links on the page background reach 4.5:1, even over a dot', () => {
    const link = token('link');
    expect(ratio(link, token('background'))).toBeGreaterThanOrEqual(4.5);
    expect(ratio(link, token('dot'))).toBeGreaterThanOrEqual(4.5);
    expect(css('base.css')).toMatch(/a\s*\{[^}]*color:\s*var\(--link\)/);
  });

  it('disabled buttons keep readable text (no fading)', () => {
    const rule = css('base.css').match(/\.btn\[disabled\]\s*\{([^}]*)\}/)![1];
    expect(rule).not.toMatch(/opacity/);
    expect(rule).toMatch(/color:\s*var\(--text-muted\)/);
  });

  it('kid buttons do not zoom on a quick double tap', () => {
    expect(css('base.css')).toMatch(/\.btn\s*\{[^}]*touch-action:\s*manipulation/);
  });

  it('a voice that never reports its end does not hold a short line for long', async () => {
    vi.useFakeTimers();
    vi.stubGlobal('speechSynthesis', {
      getVoices: () => [{ lang: 'vi-VN', name: 'vi' }],
      speak: () => {},
      cancel: () => {},
    });
    vi.stubGlobal('SpeechSynthesisUtterance', class { constructor(public text: string) {} });
    let done = false;
    void speak('Đúng rồi!').then(() => (done = true));
    await vi.advanceTimersByTimeAsync(2600);
    expect(done).toBe(true);
  });
});

describe('muting mid-round', () => {
  it('swaps only the letter questions still to come', async () => {
    const { makeRound } = await import('../src/quiz/generate');
    const { withoutLetters } = await import('../src/quiz/options');
    let seed = 1;
    const rng = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
    const round = makeRound(rng, { voice: true });
    const at = round.findIndex((q) => q.kind === 'letter');
    const next = withoutLetters(round, at, rng);
    expect(next.filter((q) => q.kind === 'letter')).toHaveLength(0);
    expect(next.slice(0, at)).toEqual(round.slice(0, at));
    expect(next).toHaveLength(round.length);
  });
});
