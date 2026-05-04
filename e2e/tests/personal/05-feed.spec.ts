import { test, expect } from '../_fixtures';

test.describe('@p1 personal feed', () => {
  test('feed personal carrega', async ({ page }) => {
    const resp = page.waitForResponse((r) =>
      r.url().match(/\/api\/feed(\?|$)/)
    );
    await page.goto('/feed');
    const r = await resp.catch(() => null);
    if (r) expect(r.status()).toBeLessThan(500);
    await expect(page).toHaveURL(/\/feed$/);
  });
});
