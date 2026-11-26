// Chíp's voice: the browser's own Vietnamese voice, or silence. Never reads
// Vietnamese with another language's voice.
import { getSoundOn } from './prefs';

let cached: SpeechSynthesisVoice | null | undefined;

export function pickVietnameseVoice(voices: SpeechSynthesisVoice[]): SpeechSynthesisVoice | null {
  return voices.find((v) => v.lang.replace('_', '-').toLowerCase().startsWith('vi')) ?? null;
}

function synth(): SpeechSynthesis | null {
  return typeof speechSynthesis === 'undefined' ? null : speechSynthesis;
}

function voice(): SpeechSynthesisVoice | null {
  if (cached !== undefined && cached !== null) return cached;
  const s = synth();
  cached = s ? pickVietnameseVoice(s.getVoices()) : null;
  return cached;
}

/** Waits (at most [ms]) for the browser to list its voices. */
export function voicesReady(ms = 1500): Promise<boolean> {
  const s = synth();
  if (!s) return Promise.resolve(false);
  if (voice()) return Promise.resolve(true);
  return new Promise((resolve) => {
    const done = () => {
      cached = undefined;
      resolve(voice() !== null);
    };
    const timer = setTimeout(done, ms);
    s.addEventListener?.('voiceschanged', () => {
      clearTimeout(timer);
      done();
    }, { once: true });
  });
}

export function hasVietnameseVoice(): boolean {
  return voice() !== null;
}

/** Reads [text]; resolves when Chíp has finished (or at once when silent). */
export function speak(text: string): Promise<void> {
  const s = synth();
  const v = voice();
  if (!s || !v || !getSoundOn()) return Promise.resolve();
  s.cancel();
  return new Promise((resolve) => {
    const u = new SpeechSynthesisUtterance(text);
    u.voice = v;
    u.lang = v.lang;
    u.rate = 0.9;
    u.onend = () => resolve();
    u.onerror = () => resolve();
    // Some browsers never fire onend: never hold the game up for long.
    setTimeout(resolve, 8000);
    s.speak(u);
  });
}

export function stopSpeaking(): void {
  synth()?.cancel();
}

export function resetSpeechForTest(): void {
  cached = undefined;
}
