import { expect, test, type Page } from '@playwright/test';

const pages = ['/', '/to-chu.html', '/do-vui.html', '/quyen-rieng-tu.html'];

/** Records every request the page makes. */
function watch(page: Page) {
  const urls: string[] = [];
  const errors: string[] = [];
  page.on('request', (r) => urls.push(r.url()));
  page.on('pageerror', (e) => errors.push(String(e)));
  page.on('console', (m) => m.type() === 'error' && errors.push(m.text()));
  return { urls, errors };
}

for (const path of pages) {
  test(`${path}: fits, big kid buttons, no outside requests, no errors`, async ({ page, baseURL }) => {
    const w = watch(page);
    await page.goto(path, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1700);
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
    expect(overflow).toBeLessThanOrEqual(0);
    for (const b of await page.locator('[data-kid]:visible').all()) {
      const box = await b.boundingBox();
      expect(box!.height, await b.textContent() ?? '').toBeGreaterThanOrEqual(64);
    }
    const origin = new URL(baseURL!).origin;
    expect(w.urls.filter((u) => !u.startsWith(origin) && !u.startsWith('data:'))).toEqual([]);
    expect(w.errors).toEqual([]);
  });
}

test('tracing số 1 with the model strokes ends with praise', async ({ page }) => {
  await page.goto('/to-chu.html?chu=so-1', { waitUntil: 'networkidle' });
  const glyph = await (await page.request.get('/generated/glyphs/so-1.json')).json();
  const canvas = page.locator('#pad');
  await canvas.scrollIntoViewIfNeeded();
  const box = (await canvas.boundingBox())!;
  for (const stroke of glyph.strokes as { points: [number, number][] }[]) {
    const pts = stroke.points.map(([x, y]) => [box.x + x * box.width, box.y + y * box.height]);
    await page.mouse.move(pts[0][0], pts[0][1]);
    await page.mouse.down();
    for (const [x, y] of pts.slice(1)) await page.mouse.move(x, y, { steps: 2 });
    await page.mouse.up();
  }
  await expect(page.locator('#praise')).toBeVisible();
});

test('five right answers end the quiz with praise', async ({ page }) => {
  await page.goto('/do-vui.html', { waitUntil: 'networkidle' });
  for (let i = 0; i < 5; i++) {
    await page.locator('#keys [data-correct]').click();
    await page.waitForTimeout(1200);
  }
  await expect(page.locator('#praise')).toBeVisible();
});

test('a store link asks an adult first', async ({ page }) => {
  await page.goto('/?test-store=1', { waitUntil: 'networkidle' });
  await page.locator('a[data-store]').click();
  await expect(page.locator('#gate')).toBeVisible();
  await page.fill('#gate-answer', '1');
  await page.click('#gate-ok');
  await expect(page.locator('#gate')).toHaveCount(0);
  expect(new URL(page.url()).pathname).toBe('/');
});
