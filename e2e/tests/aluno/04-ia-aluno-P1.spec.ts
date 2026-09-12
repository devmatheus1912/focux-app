import { test, expect } from '../_fixtures';

/**
 * IA generativa é só PERSONAL. Deep link legado /ia/aluno não fica no shell aluno.
 */
test.describe('@p1 aluno sem IA generativa', () => {
  test('rota /ia/aluno não fica no app do aluno', async ({ page }) => {
    await page.goto('/ia/aluno');
    await page.waitForLoadState('networkidle');
    await expect(page).not.toHaveURL(/\/ia\/aluno$/);
  });
});
