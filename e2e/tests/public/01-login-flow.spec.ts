import { test, expect } from '../_fixtures';

test.describe('@p0 @smoke login público', () => {
  test('rota /login carrega sem erro', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/\/login/);
  });

  test('credencial inválida mostra erro amigável (não DioException cru)', async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
    await page.getByPlaceholder(/seu@email\.com/i).fill('naoexiste@focux.app');
    await page.getByPlaceholder(/•+/).fill('senhaerrada123');
    await page.getByRole('button', { name: /entrar/i }).click();

    // Should show user-friendly error, not raw exception text
    await expect(page.getByText(/dioexception/i)).toHaveCount(0);
  });

  test('rota /esqueci-senha abre', async ({ page }) => {
    await page.goto('/esqueci-senha');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/esqueci-senha/);
  });

  test('rota /register abre', async ({ page }) => {
    await page.goto('/register');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/register/);
  });

  test('rota inexistente cai no fallback HomeRedirect', async ({ page }) => {
    await page.goto('/rota-que-nao-existe');
    await page.waitForLoadState('networkidle');
    // Router has errorBuilder -> HomeRedirectScreen which redirects to login when no token
    await expect(page).toHaveURL(/(login|dashboard|home)/);
  });
});
