import { existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
import { defineConfig } from 'vite';

const pages = ['index', 'to-chu', 'do-vui', 'quyen-rieng-tu'].filter((p) =>
  existsSync(resolve(__dirname, `${p}.html`)),
);

export default defineConfig({
  build: {
    target: 'es2020',
    rollupOptions: {
      input: Object.fromEntries(pages.map((p) => [p, resolve(__dirname, `${p}.html`)])),
    },
  },
});
