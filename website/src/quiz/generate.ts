// The quiz round: count stars, add within 5, and (with a Vietnamese voice)
// "which letter did Chíp say?". Pure: give it a random source.

export type Q = {
  kind: 'count' | 'add' | 'letter';
  prompt: string;
  speech: string;
  choices: string[];
  correct: number;
  stars?: number;
  a?: number;
  b?: number;
  letterSpeech?: string;
};

/** Letters that are easy to mix up, asked together. */
export const LETTER_GROUPS: string[][] = [
  ['b', 'd', 'h'],
  ['o', 'a', 'e'],
  ['c', 'e', 'o'],
];

/** How Chíp says each letter (the app's letter names). */
export const LETTER_NAMES: Record<string, string> = {
  a: 'chữ a', b: 'chữ bờ', c: 'chữ cờ', d: 'chữ dờ', e: 'chữ e', h: 'chữ hờ', o: 'chữ o',
};

type Rng = () => number;
const int = (rng: Rng, lo: number, hi: number) => lo + Math.floor(rng() * (hi - lo + 1));

function shuffle<T>(rng: Rng, xs: T[]): T[] {
  const a = [...xs];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** Three distinct numbers in [lo, hi] around [answer]; returns choices + index. */
function numberChoices(rng: Rng, answer: number, lo: number, hi: number) {
  const pool = [];
  for (let n = lo; n <= hi; n++) if (n !== answer) pool.push(n);
  pool.sort((x, y) => Math.abs(x - answer) - Math.abs(y - answer) || rng() - 0.5);
  const choices = shuffle(rng, [answer, ...pool.slice(0, 2)]).map(String);
  return { choices, correct: choices.indexOf(String(answer)) };
}

function count(rng: Rng): Q {
  const stars = int(rng, 1, 5);
  return {
    kind: 'count',
    prompt: 'Có bao nhiêu ngôi sao?',
    speech: 'Có bao nhiêu ngôi sao?',
    stars,
    ...numberChoices(rng, stars, 1, 6),
  };
}

function add(rng: Rng): Q {
  const a = int(rng, 1, 4);
  const b = int(rng, 0, 5 - a);
  return {
    kind: 'add',
    prompt: `${a} + ${b} = ?`,
    speech: `${a} cộng ${b} bằng mấy?`,
    a,
    b,
    ...numberChoices(rng, a + b, 0, 6),
  };
}

function letter(rng: Rng): Q {
  const group = LETTER_GROUPS[int(rng, 0, LETTER_GROUPS.length - 1)];
  const answer = group[int(rng, 0, group.length - 1)];
  const choices = shuffle(rng, group);
  const name = LETTER_NAMES[answer];
  return {
    kind: 'letter',
    prompt: 'Chíp đọc chữ nào?',
    speech: `Chíp đọc chữ nào? ${name}`,
    letterSpeech: name,
    choices,
    correct: choices.indexOf(answer),
  };
}

export function makeRound(rng: Rng, opts: { voice: boolean }): Q[] {
  const kinds = opts.voice
    ? ['count', 'add', 'letter', 'count', 'add']
    : ['count', 'add', 'count', 'add', 'count'];
  return shuffle(rng, kinds).map((k) => (k === 'count' ? count(rng) : k === 'add' ? add(rng) : letter(rng)));
}
