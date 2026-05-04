import { test, expect } from '../_fixtures';

test.describe('@p1 personal broadcasts', () => {
  test('rota /broadcasts abre', async ({ page }) => {
    await page.goto('/broadcasts');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/broadcasts/);
  });

  test('GET /api/broadcasts (histórico) não retorna 500', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/broadcasts') && r.request().method() === 'GET'
    );
    await page.goto('/broadcasts');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
  });
});
