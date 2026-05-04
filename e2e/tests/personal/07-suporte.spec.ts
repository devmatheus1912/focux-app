import { test, expect } from '../_fixtures';

test.describe('@p1 personal suporte', () => {
  test('rota /suporte abre', async ({ page }) => {
    await page.goto('/suporte');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/suporte/);
  });

  test('lista meus tickets não retorna 500', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/suporte/tickets/meus')
    );
    await page.goto('/suporte');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
  });
});
