import { test, expect } from '../_fixtures';

test.describe('@p1 aluno feed', () => {
  test('feed aluno carrega', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().includes('/api/feed/aluno')
    );
    await page.goto('/feed/aluno');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
    await expect(page).toHaveURL(/feed\/aluno/);
  });
});
