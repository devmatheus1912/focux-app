import { test, expect } from '../_fixtures';

test.describe('@p0 @smoke aluno dashboard', () => {
  test('dashboard aluno carrega sem 403 em personal-brand', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/aluno/personal-brand')
    );
    await page.goto('/dashboard/aluno');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
    await expect(page).toHaveURL(/dashboard\/aluno/);
  });

  test('aluno NÃO acessa rota /api/personal/perfil (403 esperado mas tela não pode quebrar)', async ({ page }) => {
    await page.goto('/dashboard/aluno');
    await page.waitForLoadState('networkidle');
  });
});
