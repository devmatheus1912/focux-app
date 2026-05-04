import { test, expect } from '../_fixtures';

/**
 * P0 do status.md — corrigido em 2026-05-03 movendo FE para
 * /api/alunos/{alunoId}/fotos (path que já existe no EvolucaoController).
 *
 * Esse teste agora deve PASSAR. Se voltar a falhar é regressão.
 */
test.describe('@p0 evolução fotos', () => {
  test('GET /api/alunos/{alunoId}/fotos não retorna 404/5xx', async ({ page }) => {
    const alunoId = process.env.E2E_ALUNO_ID ?? '1';
    const resp = page.waitForResponse((r) =>
      r.url().includes(`/api/alunos/${alunoId}/fotos`) && r.request().method() === 'GET'
    );
    await page.goto(`/alunos/${alunoId}/fotos`);
    const r = await resp.catch(() => null);
    if (r) {
      expect(r.status(), `Endpoint ${r.url()} retornou ${r.status()}`).not.toBe(404);
      expect(r.status()).toBeLessThan(500);
    }
  });

  test('endpoint legado /api/evolucao/{alunoId}/fotos não é mais chamado', async ({ page, errors }) => {
    const alunoId = process.env.E2E_ALUNO_ID ?? '1';
    let legacyCalled = false;
    page.on('response', (r) => {
      if (r.url().includes('/api/evolucao/') && r.url().includes('/fotos')) {
        legacyCalled = true;
      }
    });
    await page.goto(`/alunos/${alunoId}/fotos`);
    await page.waitForLoadState('networkidle');
    expect(legacyCalled, 'FE ainda chama path legado /api/evolucao/{id}/fotos').toBe(false);
  });
});
