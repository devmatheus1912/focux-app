import { test, expect } from '../_fixtures';

test.describe('@p0 personal alunos', () => {
  test('lista de alunos carrega', async ({ page }) => {
    await page.goto('/alunos');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/alunos$/);
  });

  test('rota /alunos/novo abre form', async ({ page }) => {
    await page.goto('/alunos/novo');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/alunos\/novo/);
  });

  test('rota /alunos/acoes-massa abre', async ({ page }) => {
    await page.goto('/alunos/acoes-massa');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/acoes-massa/);
  });

  test('alias /kanban redireciona para acoes-massa', async ({ page }) => {
    await page.goto('/kanban');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/acoes-massa/);
  });

  test('rota /alunos/:id detalhe abre', async ({ page }) => {
    const alunoId = process.env.E2E_ALUNO_ID ?? '1';
    await page.goto(`/alunos/${alunoId}`);
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(new RegExp(`alunos\\/${alunoId}`));
  });
});
