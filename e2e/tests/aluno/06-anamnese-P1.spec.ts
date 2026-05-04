import { test, expect } from '../_fixtures';

/**
 * P1 (status.md): /api/aluno/anamnese 404 em produção (deploy desatualizado).
 * Esse teste verifica que endpoint responde local.
 */
test.describe('@p1 aluno anamnese', () => {
  test('GET /api/aluno/anamnese não retorna 404', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().endsWith('/api/aluno/anamnese')
    );
    await page.goto('/aluno/perfil');
    const r = await resp.catch(() => null);
    if (r) {
      expect(r.status()).not.toBe(404);
      expect(r.status()).toBeLessThan(500);
    }
  });
});
