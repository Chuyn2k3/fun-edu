// Bits shared by the play pages: the top bar and the sound switch.
import { getSoundOn, setSoundOn } from './prefs';
import { hasVietnameseVoice, stopSpeaking } from './speech';

export const img = (name: string) => `/generated/img/${name}.webp`;

export function topBar(title: string): HTMLElement {
  const bar = document.createElement('header');
  bar.className = 'top';
  bar.innerHTML = `
    <a class="btn" href="/" aria-label="Về trang chính" data-kid>‹</a>
    <h1>${title}</h1>
    <button class="btn" id="sound" data-kid hidden></button>`;
  const sound = bar.querySelector<HTMLButtonElement>('#sound')!;
  const paint = () => {
    const on = getSoundOn();
    sound.textContent = on ? '🔊' : '🔇';
    sound.setAttribute('aria-label', on ? 'Tắt tiếng' : 'Bật tiếng');
  };
  sound.addEventListener('click', () => {
    setSoundOn(!getSoundOn());
    if (!getSoundOn()) stopSpeaking();
    paint();
  });
  paint();
  return bar;
}

/** Shows the sound switch once we know a Vietnamese voice exists. */
export function revealSound(bar: HTMLElement): void {
  const sound = bar.querySelector<HTMLButtonElement>('#sound');
  if (sound) sound.hidden = !hasVietnameseVoice();
}

export function downloadCard(): string {
  return `
    <div class="card cta">
      <h3>Muốn học tiếp cùng Chíp?</h3>
      <p class="muted">Ứng dụng ChipChip có đủ chữ cái, số, Toán, Tiếng Việt, Tiếng Anh và trò chơi.</p>
      <a class="btn primary" href="/#tai-app" data-kid>Tải ChipChip</a>
    </div>`;
}
