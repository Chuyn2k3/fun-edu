// Copies the shared app assets the site needs into public/generated/.
// Never edit the copies: they are rebuilt from assets/ on every build.
import { copyFileSync, mkdirSync, rmSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const site = join(dirname(fileURLToPath(import.meta.url)), '..');
const repo = join(site, '..');
const out = join(site, 'public', 'generated');
const traceItems = ['so-1', 'so-2', 'so-3', 'chu-a', 'chu-o', 'chu-b', 'chu-c', 'chu-e'];
const quizLetters = ['chu-d', 'chu-h'];

rmSync(out, { recursive: true, force: true });
mkdirSync(join(out, 'glyphs'), { recursive: true });
for (const id of [...traceItems, ...quizLetters]) {
  copyFileSync(join(repo, 'assets/glyphs', `${id}.json`), join(out, 'glyphs', `${id}.json`));
}
console.log(`copied ${traceItems.length + quizLetters.length} glyphs`);
