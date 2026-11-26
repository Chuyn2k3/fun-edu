import { afterEach, describe, expect, it, vi } from 'vitest';
import { getSoundOn, setSoundOn } from '../src/lib/prefs';

describe('sound preference', () => {
  afterEach(() => {
    vi.restoreAllMocks();
    localStorage.clear();
  });

  it('remembers sound off', () => {
    setSoundOn(false);
    expect(getSoundOn()).toBe(false);
    setSoundOn(true);
    expect(getSoundOn()).toBe(true);
  });

  it('works when storage throws', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new Error('blocked');
    });
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new Error('blocked');
    });
    expect(getSoundOn()).toBe(true);
    expect(() => setSoundOn(false)).not.toThrow();
  });
});
