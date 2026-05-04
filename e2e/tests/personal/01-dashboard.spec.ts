import { test, expect } from '../_fixtures';

test.describe('@p0 @smoke personal dashboard', () => {
  test('dashboard personal carrega com sessão', async ({ page }) => {
    await page.goto('/dashboard/personal');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/dashboard\/personal/);
  });

  test('todas 5 tabs do shell são alcançáveis', async ({ page }) => {
    const tabs = [
      '/dashboard/personal',
      '/alunos',
      '/treinos',
      '/agenda',
      '/ia/copiloto',
    ];
    for (const path of tabs) {
      await page.goto(path);
      await page.waitForLoadState('networkidle');
      await expect(page).toHaveURL(new RegExp(path.replace(/\//g, '\\/')));
    }
  });

  test('command-center: GET /api/dashboard/command-center responde', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/dashboard/command-center') && r.request().method() === 'GET'
    );
    await page.goto('/dashboard/personal');
    const r = await resp;
    expect(r.status()).toBeLessThan(500);
  });
});
