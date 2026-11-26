import '../styles/tokens.css';
import '../styles/base.css';
import '../styles/trace.css';
import { SITE } from '../config';
import { downloadCard, img, revealSound, topBar } from '../lib/chrome';
import { hasVietnameseVoice, speak, stopSpeaking, voicesReady } from '../lib/speech';
import { inWindow, parseGlyph, spokenName, type Glyph } from '../stroke/glyph';
import { GlyphSession } from '../stroke/session';
import { TracePad } from '../trace/pad';
import { errorLine, nextStroke, praise, tracePrompt } from '../trace/messages';

const app = document.getElementById('app')!;
const bar = topBar('Tô chữ');
app.append(bar);
app.insertAdjacentHTML(
  'beforeend',
  `
  <nav class="items" aria-label="Chọn chữ"></nav>
  <div class="chip-row"><img id="chip" alt="Chíp Chíp" src="${img('chip-main')}"><div class="bubble" id="bubble">Chọn một chữ để tô nhé!</div></div>
  <div class="pad-wrap"><canvas id="pad" aria-label="Vùng tô chữ"></canvas></div>
  <div class="actions">
    <button class="btn" id="listen" data-kid hidden>🔊 Nghe</button>
    <button class="btn" id="hint" data-kid>👀 Xem mẫu</button>
    <button class="btn" id="again" data-kid>↺ Tô lại</button>
  </div>
  ${downloadCard()}`,
);

const nav = app.querySelector<HTMLElement>('.items')!;
const bubble = document.getElementById('bubble')!;
const chip = document.getElementById('chip') as HTMLImageElement;
const canvas = document.getElementById('pad') as HTMLCanvasElement;
const listen = document.getElementById('listen') as HTMLButtonElement;

const glyphs = new Map<string, Glyph>();
let current: Glyph | null = null;
let session: GlyphSession | null = null;

const say = (text: string, face = 'chip-main') => {
  bubble.textContent = text;
  chip.src = img(face);
  void speak(text);
};

const pad = new TracePad(canvas, (stroke) => {
  if (!session || !current || session.isComplete) return;
  const r = session.submit(stroke);
  pad.setGlyph(current, session.currentIndex);
  if (!r.ok) {
    say(errorLine[r.error!], 'chip-encourage');
    pad.flashHint();
    return;
  }
  if (session.isComplete) {
    finish();
  } else {
    say(nextStroke(session.currentIndex + 1), 'chip-joy');
  }
});

function select(id: string) {
  const g = glyphs.get(id);
  if (!g) return;
  current = g;
  session = new GlyphSession(g);
  for (const b of nav.querySelectorAll('button')) {
    b.setAttribute('aria-pressed', String(b.dataset.id === id));
  }
  pad.setGlyph(g, 0);
  pad.resize();
  const name = spokenName(g);
  say(`${name.charAt(0).toUpperCase()}${name.slice(1)}. ${tracePrompt(1, g.strokes.length)}`);
}

function finish() {
  if (!current) return;
  const name = spokenName(current);
  say(praise(name), 'chip-thumb');
  const ids = SITE.traceItems;
  const next = ids[(ids.indexOf(current.id) + 1) % ids.length];
  const overlay = document.createElement('div');
  overlay.className = 'overlay';
  overlay.innerHTML = `
    <div class="card" role="dialog" aria-live="polite" id="praise">
      <img src="${img('chip-joy')}" alt="">
      <h2>${praise(current.label)}</h2>
      <div class="row">
        <button class="btn primary" id="next" data-kid>Chữ tiếp theo</button>
        <a class="btn" href="/#tai-app" data-kid>Tải ChipChip để học tiếp</a>
      </div>
    </div>`;
  document.body.append(overlay);
  overlay.querySelector('#next')!.addEventListener('click', () => {
    overlay.remove();
    select(next);
  });
}

document.getElementById('hint')!.addEventListener('click', () => pad.flashHint());
document.getElementById('again')!.addEventListener('click', () => current && select(current.id));
listen.addEventListener('click', () => current && void speak(spokenName(current)));
window.addEventListener('pagehide', stopSpeaking);

async function start() {
  const loaded = await Promise.all(
    SITE.traceItems.map(async (id) => {
      const res = await fetch(`/generated/glyphs/${id}.json`);
      return inWindow(parseGlyph(await res.json()));
    }),
  );
  for (const g of loaded) {
    glyphs.set(g.id, g);
    const b = document.createElement('button');
    b.className = 'btn';
    b.dataset.id = g.id;
    b.dataset.kid = '';
    b.textContent = g.label.replace(/^(Số|Chữ) /, '');
    b.setAttribute('aria-label', g.label);
    b.addEventListener('click', () => select(g.id));
    nav.append(b);
  }
  const fromUrl = new URLSearchParams(location.search).get('chu');
  select(fromUrl && glyphs.has(fromUrl) ? fromUrl : SITE.traceItems[0]);
  await voicesReady();
  listen.hidden = !hasVietnameseVoice();
  revealSound(bar);
}

void start();
