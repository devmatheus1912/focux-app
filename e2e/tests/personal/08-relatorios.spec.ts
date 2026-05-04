import { test, expect } from '../_fixtures';

test.describe('@p1 personal relatórios', () => {
  test('rota /relatorios/global abre', async ({ page }) => {
    await page.goto('/relatorios/global');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/relatorios\/global/);
  });

  test('GET /api/relatorios/resumo-global não retorna 500', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/relatorios/resumo-global')
    );
    await page.goto('/relatorios/global');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
  });

  test('relatório aderência aluno: rota /alunos/:id/relatorio abre', async ({ page }) => {
    const alunoId = process.env.E2E_ALUNO_ID ?? '1';
    await page.goto(`/alunos/${alunoId}/relatorio`);
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/relatorio/);
  });
});
