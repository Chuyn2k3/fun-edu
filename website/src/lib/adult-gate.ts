// A light adult check before anything leaves the site (store links): a
// multiplication written in words, like the app's parent gate.
const WORDS = ['', '', '', '', '', '', 'Sáu', 'Bảy', 'Tám', 'Chín'];
const lower = (w: string) => w.toLowerCase();

export function gateQuestion(rng: () => number = Math.random): { text: string; answer: number } {
  const a = 6 + Math.floor(rng() * 4);
  const b = 6 + Math.floor(rng() * 4);
  return { text: `${WORDS[a]} nhân ${lower(WORDS[b])} bằng mấy?`, answer: a * b };
}

/** Resolves true only when the answer is right. */
export function askAdult(rng: () => number = Math.random): Promise<boolean> {
  const q = gateQuestion(rng);
  return new Promise((resolve) => {
    const overlay = document.createElement('div');
    overlay.className = 'overlay';
    overlay.id = 'gate';
    overlay.innerHTML = `
      <form class="card" role="dialog" aria-labelledby="gate-title">
        <h2 id="gate-title">Dành cho ba mẹ</h2>
        <p>${q.text}</p>
        <input id="gate-answer" inputmode="numeric" autocomplete="off" aria-label="Câu trả lời"
          style="font: inherit; font-size: 28px; width: 140px; text-align: center; padding: 8px; border-radius: 14px; border: 2px solid var(--dot)">
        <div class="row">
          <button class="btn primary" id="gate-ok" type="submit">Tiếp tục</button>
          <button class="btn" id="gate-cancel" type="button">Hủy</button>
        </div>
      </form>`;
    const close = (ok: boolean) => {
      overlay.remove();
      resolve(ok);
    };
    const form = overlay.querySelector('form')!;
    const input = overlay.querySelector<HTMLInputElement>('#gate-answer')!;
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      close(Number(input.value.trim()) === q.answer);
    });
    overlay.querySelector('#gate-ok')!.addEventListener('click', (e) => {
      e.preventDefault();
      close(Number(input.value.trim()) === q.answer);
    });
    overlay.querySelector('#gate-cancel')!.addEventListener('click', () => close(false));
    document.body.append(overlay);
    input.focus();
  });
}
