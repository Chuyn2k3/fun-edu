// Per-device conveniences only. Storage may be blocked (private mode,
// cleared site data): every access is guarded and has a default.
const SOUND_KEY = 'chipchip.sound';

export function getSoundOn(): boolean {
  try {
    return localStorage.getItem(SOUND_KEY) !== 'off';
  } catch {
    return true;
  }
}

export function setSoundOn(on: boolean): void {
  try {
    localStorage.setItem(SOUND_KEY, on ? 'on' : 'off');
  } catch {
    // Not remembered on this device; the page still works.
  }
}
