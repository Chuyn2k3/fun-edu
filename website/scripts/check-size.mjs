// Fails the build when the site grows past its budget (spec §5.5).
import { gzipSync } from 'node:zlib';
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const dist = join(dirname(fileURLToPath(import.meta.url)), '..', 'dist');
const walk = (d) => readdirSync(d).flatMap((f) => {
  const p = join(d, f);
  return statSync(p).isDirectory() ? walk(p) : [p];
});
const files = walk(dist);
const gz = (p) => gzipSync(readFileSync(p)).length;
const js = files.filter((f) => f.endsWith('.js')).reduce((n, f) => n + gz(f), 0);
const firstPage = files
  .filter((f) => /\.(js|css|woff2)$/.test(f) || f.endsWith('index.html') ||
    /chip-main\.webp$/.test(f) || /logo\.webp$/.test(f))
  .reduce((n, f) => n + (f.endsWith('.webp') || f.endsWith('.woff2') ? statSync(f).size : gz(f)), 0);
const kb = (n) => (n / 1024).toFixed(1) + ' KB';
console.log(`JS gzip ${kb(js)} (≤ 60 KB), first page ${kb(firstPage)} (≤ 400 KB)`);
if (js > 60 * 1024 || firstPage > 400 * 1024) {
  console.error('Size budget exceeded');
  process.exit(1);
}
