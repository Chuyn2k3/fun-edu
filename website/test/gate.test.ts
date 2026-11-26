import { afterEach, describe, expect, it } from 'vitest';
import { askAdult, gateQuestion } from '../src/lib/adult-gate';

const fixed = () => 0; // a = b = 6

function answer(value: string, button: '#gate-ok' | '#gate-cancel' = '#gate-ok') {
  const input = document.querySelector<HTMLInputElement>('#gate-answer')!;
  input.value = value;
  document.querySelector<HTMLButtonElement>(button)!.click();
}

describe('adult gate', () => {
  afterEach(() => document.body.replaceChildren());

  it('asks a multiplication in words, without digits', () => {
    for (const r of [0, 0.3, 0.6, 0.99]) {
      const q = gateQuestion(() => r);
      expect(q.text).toMatch(/nhân/);
      expect(/\d/.test(q.text)).toBe(false);
      expect(q.answer).toBeGreaterThanOrEqual(36);
    }
    expect(gateQuestion(fixed)).toEqual({ text: 'Sáu nhân sáu bằng mấy?', answer: 36 });
  });

  it('a right answer lets the adult through', async () => {
    const p = askAdult(fixed);
    answer('36');
    await expect(p).resolves.toBe(true);
    expect(document.querySelector('#gate')).toBeNull();
  });

  it('a wrong answer or cancel keeps the child out', async () => {
    const wrong = askAdult(fixed);
    answer('35');
    await expect(wrong).resolves.toBe(false);
    const cancel = askAdult(fixed);
    answer('', '#gate-cancel');
    await expect(cancel).resolves.toBe(false);
  });
});
