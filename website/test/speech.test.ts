import { afterEach, describe, expect, it, vi } from 'vitest';
import { pickVietnameseVoice, speak, resetSpeechForTest } from '../src/lib/speech';

const voice = (lang: string, name = lang) => ({ lang, name }) as SpeechSynthesisVoice;

function fakeSynth(voices: SpeechSynthesisVoice[]) {
  const spoken: string[] = [];
  const synth = {
    getVoices: () => voices,
    speak: vi.fn((u: { text: string; onend?: () => void }) => {
      spoken.push(u.text);
      u.onend?.();
    }),
    cancel: vi.fn(),
    addEventListener: vi.fn(),
  };
  vi.stubGlobal('speechSynthesis', synth);
  vi.stubGlobal(
    'SpeechSynthesisUtterance',
    class {
      text: string;
      voice: unknown = null;
      lang = '';
      rate = 1;
      onend?: () => void;
      onerror?: () => void;
      constructor(t: string) {
        this.text = t;
      }
    },
  );
  return { synth, spoken };
}

describe('speech', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    resetSpeechForTest();
    localStorage.clear();
  });

  it('picks a Vietnamese voice only', () => {
    expect(pickVietnameseVoice([voice('en-US'), voice('vi-VN', 'Linh')])?.name).toBe('Linh');
    expect(pickVietnameseVoice([voice('en-US'), voice('fr-FR')])).toBeNull();
  });

  it('stays silent without a Vietnamese voice', async () => {
    const { synth } = fakeSynth([voice('en-US')]);
    await speak('xin chào');
    expect(synth.speak).not.toHaveBeenCalled();
  });

  it('speaks with the Vietnamese voice and resolves at the end', async () => {
    const { spoken } = fakeSynth([voice('vi-VN')]);
    await speak('xin chào');
    expect(spoken).toEqual(['xin chào']);
  });

  it('stays silent when sound is off', async () => {
    localStorage.setItem('chipchip.sound', 'off');
    const { synth } = fakeSynth([voice('vi-VN')]);
    await speak('xin chào');
    expect(synth.speak).not.toHaveBeenCalled();
  });
});
