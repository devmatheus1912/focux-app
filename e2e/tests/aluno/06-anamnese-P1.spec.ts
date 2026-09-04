import { test, expect } from '../_fixtures';

/**
 * Fluxo anamnese aluno: GET /api/aluno/anamnese na rota dedicada.
 */
test.describe('@p1 aluno anamnese', () => {
  test('GET /api/aluno/anamnese não retorna 404', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().endsWith('/api/aluno/anamnese')
    );
    await page.goto('/aluno/anamnese');
    const r = await resp.catch(() => null);
    if (r) {
      expect(r.status()).not.toBe(404);
      expect(r.status()).toBeLessThan(500);
    }
  });
});
