import { test, expect } from '../_fixtures';

/**
 * P0 smoke — hubs refatorados (parts) devem abrir sem whitescreen nem 5xx.
 * Complementa personal/10-rotas-shell.spec.ts com asserts de API e URL.
 */
test.describe('@p0 @smoke rotas críticas — hubs refatorados', () => {
  test('chat inbox carrega e inbox API responde', async ({ page }) => {
    const inboxResp = page.waitForResponse(
      (r) => r.url().includes('/api/chat/inbox') && r.request().method() === 'GET',
    );
    await page.goto('/chat/inbox');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/chat\/inbox/);
    const r = await inboxResp;
    expect(r.status()).toBeLessThan(500);
  });

  test('copiloto abre shell IA', async ({ page }) => {
    await page.goto('/ia/copiloto');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/ia\/copiloto/);
  });

  test('migracao magica abre fluxo premium', async ({ page }) => {
    await page.goto('/migracao-magica');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/migracao-magica/);
  });

  test('exercicios lista e detalhe respondem', async ({ page }) => {
    const listResp = page.waitForResponse(
      (r) => r.url().includes('/api/exercicios') && r.request().method() === 'GET',
    );
    await page.goto('/exercicios');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/exercicios$/);
    const list = await listResp;
    expect(list.status()).toBeLessThan(500);

    const detailResp = page.waitForResponse(
      (r) =>
        r.url().includes('/api/exercicios/') &&
        r.request().method() === 'GET' &&
        !r.url().includes('?'),
    );
    await page.goto('/exercicios/1');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/exercicios\/1/);
    const detail = await detailResp;
    expect(detail.status()).toBeLessThan(500);
  });
});
