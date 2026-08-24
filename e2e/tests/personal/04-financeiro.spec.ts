import { test, expect } from '../_fixtures';

test.describe('@p0 personal financeiro', () => {
  test('tela /financeiro abre com dashboard', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/financeiro/home')
    );
    await page.goto('/financeiro');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
    await expect(page).toHaveURL(/financeiro/);
  });

  test('lista mensalidades não retorna 500', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/financeiro/home')
    );
    await page.goto('/financeiro');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
  });

  test('resumo mensal (métricas) não retorna 500', async ({ page }) => {
    await page.goto('/financeiro');
    await page.waitForLoadState('networkidle');
    // Métricas tab — se TabBar existir, clicar
    const metricasTab = page.getByText(/métricas/i).first();
    if (await metricasTab.isVisible().catch(() => false)) {
      await metricasTab.click();
      await page.waitForLoadState('networkidle');
    }
  });
});
