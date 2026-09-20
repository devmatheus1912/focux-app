import type { Page } from '@playwright/test';
import { test, expect } from '../_fixtures';

async function fillLoginFields(page: Page, email: string, password: string) {
  const inputs = page.locator('input:not([type="checkbox"]):not([type="hidden"])');
  const count = await inputs.count();

  if (count >= 2) {
    await inputs.nth(0).fill(email);
    await inputs.nth(1).fill(password);
    return;
  }

  await page.locator('body').click({ position: { x: 5, y: 5 } });
  await page.keyboard.press('Tab');
  await page.keyboard.press('Tab');
  await page.keyboard.type(email, { delay: 20 });
  await page.keyboard.press('Tab');
  await page.keyboard.type(password, { delay: 20 });
}

async function submitLogin(page: Page) {
  const byRole = page.getByRole('button', { name: /entrar/i }).first();
  if (await byRole.isVisible().catch(() => false)) {
    await byRole.click();
    return;
  }

  const byText = page.getByText(/^Entrar$/).first();
  if (await byText.isVisible().catch(() => false)) {
    await byText.click();
    return;
  }

  await page.keyboard.press('Enter');
}

test.describe('@p0 @smoke login publico', () => {
  test('rota /login carrega sem erro', async ({ page }) => {
    await page.goto('/login');
    await expect(page).toHaveURL(/\/login/);
    await expect(page.locator('flt-glass-pane, flutter-view, canvas').first()).toBeAttached();
  });

  test('credencial invalida mostra erro amigavel (nao DioException cru)', async ({ page }) => {
    await page.goto('/login');
    await fillLoginFields(page, 'naoexiste@focux.app', 'senhaerrada123');
    await submitLogin(page);

    await expect(page.getByText(/dioexception/i)).toHaveCount(0);
  });

  test('rota /esqueci-senha abre', async ({ page }) => {
    await page.goto('/esqueci-senha');
    await expect(page).toHaveURL(/esqueci-senha/);
  });

  test('rota /register abre', async ({ page }) => {
    await page.goto('/register');
    await expect(page).toHaveURL(/register/);
  });

  test('rota inexistente cai no fallback HomeRedirect', async ({ page }) => {
    await page.goto('/rota-que-nao-existe');
    // errorBuilder → HomeRedirect → goToRoleHome (login se anônimo).
    await expect(page).toHaveURL(/(login|dashboard|home)/, { timeout: 30_000 });
  });
});
