import { test, expect } from '../_fixtures';

/**
 * P1: /ia/aluno (chat) não pode morrer em 403 fatal.
 * Progressão de carga é só PERSONAL — não cobre /api/ia/progressao-carga aqui.
 */
test.describe('@p1 aluno IA (regressão 403)', () => {
  test('rota /ia/aluno abre sem 403 fatal', async ({ page, errors }) => {
    await page.goto('/ia/aluno');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/ia\/aluno/);

    const ia403 = errors.find((e) => /403.*\/api\/ia\//i.test(e));
    expect(ia403, `IA voltou a dar 403 para aluno: ${ia403}`).toBeUndefined();
  });
});
