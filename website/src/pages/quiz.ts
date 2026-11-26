import '../styles/tokens.css';
import '../styles/base.css';
import '../styles/trace.css';
import '../styles/quiz.css';
import { downloadCard, img, revealSound, topBar } from '../lib/chrome';
import { hasVietnameseVoice, speak, stopSpeaking, voicesReady } from '../lib/speech';
import { makeRound, type Q } from '../quiz/generate';

const TEST = import.meta.env.MODE === 'test';
const app = document.getElementById('app')!;
const bar = topBar('Đố vui');
app.append(bar);
app.insertAdjacentHTML(
  'beforeend',
  `
  <div class="dots" id="dots"></div>
  <div class="chip-row"><img id="chip" alt="Chíp Chíp" src="${img('chip-main')}"><div class="bubble" id="bubble">Chơi cùng Chíp nào!</div></div>
  <div class="card qcard" id="qcard"></div>
  <div class="keys" id="keys"></div>
  ${downloadCard()}`,
);

const bubble = document.getElementById('bubble')!;
const chip = document.getElementById('chip') as HTMLImageElement;
const qcard = document.getElementById('qcard')!;
const keys = document.getElementById('keys')!;
const dots = document.getElementById('dots')!;

let round: Q[] = [];
let index = 0;
let busy = false;

const face = (name: string) => (chip.src = img(name));

function paintDots() {
  dots.innerHTML = round
    .map((_, i) => `<span class="${i < index ? 'done' : i === index ? 'on' : ''}"></span>`)
    .join('');
}

function show() {
  const q = round[index];
  busy = false;
  face('chip-main');
  bubble.textContent = q.prompt;
  paintDots();
  if (q.kind === 'count') {
    qcard.innerHTML = `<div class="stars" aria-label="${q.stars} ngôi sao">${Array.from(
      { length: q.stars! },
      () => `<img src="${img('ic-star')}" alt="">`,
    ).join('')}</div>`;
  } else if (q.kind === 'add') {
    qcard.innerHTML = `<div class="sum">${q.prompt}</div>`;
  } else {
    qcard.innerHTML = `<button class="btn listen" data-kid aria-label="Nghe lại">🔊</button>`;
    qcard.querySelector('button')!.addEventListener('click', () => void speak(q.letterSpeech!));
  }
  keys.innerHTML = '';
  q.choices.forEach((c, i) => {
    const b = document.createElement('button');
    b.className = 'btn';
    b.dataset.kid = '';
    b.textContent = c;
    if (TEST && i === q.correct) b.dataset.correct = '';
    b.addEventListener('click', () => pick(i, b));
    keys.append(b);
  });
  void speak(q.speech);
}

async function pick(i: number, b: HTMLButtonElement) {
  if (busy) return;
  const q = round[index];
  if (i !== q.correct) {
    b.classList.remove('wrong');
    void b.offsetWidth; // restart the shake
    b.classList.add('wrong');
    face('chip-encourage');
    bubble.textContent = 'Thử lại nhé!';
    void speak('Thử lại nhé!');
    return;
  }
  busy = true;
  b.classList.add('right');
  face('chip-joy');
  bubble.textContent = 'Đúng rồi!';
  await Promise.all([speak('Đúng rồi!'), new Promise((r) => setTimeout(r, 900))]);
  index++;
  if (index < round.length) show();
  else finish();
}

function finish() {
  paintDots();
  face('chip-thumb');
  bubble.textContent = 'Bé giỏi quá!';
  void speak('Bé giỏi quá!');
  const overlay = document.createElement('div');
  overlay.className = 'overlay';
  overlay.innerHTML = `
    <div class="card" role="dialog" id="praise">
      <img src="${img('chip-joy')}" alt="">
      <h2>Bé giỏi quá!</h2>
      <p class="muted">Bé đã trả lời đúng cả 5 câu.</p>
      <div class="row">
        <button class="btn primary" id="again" data-kid>Chơi tiếp</button>
        <a class="btn" href="/#tai-app" data-kid>Tải ChipChip để học tiếp</a>
      </div>
    </div>`;
  document.body.append(overlay);
  overlay.querySelector('#again')!.addEventListener('click', () => {
    overlay.remove();
    newRound();
  });
}

function newRound() {
  round = makeRound(Math.random, { voice: hasVietnameseVoice() });
  index = 0;
  show();
}

window.addEventListener('pagehide', stopSpeaking);
void voicesReady().then(() => {
  revealSound(bar);
  newRound();
});
