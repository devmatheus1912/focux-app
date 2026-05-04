import { test as setup, expect } from '@playwright/test';
import 'dotenv/config';
import { mkdirSync } from 'node:fs';
import { enableFlutterSemantics } from './_fixtures';

const FILE = '.auth/personal.json';
const BASE_URL = process.env.E2E_BASE_URL ?? 'http://localhost:61791';

setup('autentica personal', async ({ page }) => {
  mkdirSync('.auth', { recursive: true });

  const email = process.env.E2E_PERSONAL_EMAIL;
  const senha = process.env.E2E_PERSONAL_SENHA;
  if (!email || !senha) {
    throw new Error('Set E2E_PERSONAL_EMAIL and E2E_PERSONAL_SENHA in .env');
  }

  await page.goto(`${BASE_URL}/#/login`);
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(2000);
  await enableFlutterSemantics(page);
  await page.waitForTimeout(1000);

  // Strategy: rely on tab order — 1st input is e-mail, 2nd is password.
  // Flutter Web exposes inputs after semantics is on. Click the page first
  // to focus the canvas, then tab through fields.
  await page.locator('body').click({ position: { x: 5, y: 5 } });
  await page.waitForTimeout(300);

  // Try to find inputs created by semantics
  const inputs = page.locator('input:not([type="checkbox"]):not([type="hidden"])');
  const count = await inputs.count();

  if (count >= 2) {
    await inputs.nth(0).click();
    await page.keyboard.type(email, { delay: 30 });
    await inputs.nth(1).click();
    await page.keyboard.type(senha, { delay: 30 });
  } else {
    // Fallback: tab navigation from top
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.type(email, { delay: 30 });
    await page.keyboard.press('Tab');
    await page.keyboard.type(senha, { delay: 30 });
  }

  // Submit: try Enter first, then click any visible Entrar button
  await page.keyboard.press('Enter');
  await page.waitForTimeout(500);

  if (!/dashboard|home/.test(page.url())) {
    const entrarBtn = page.getByText(/^Entrar$/).first();
    if (await entrarBtn.isVisible().catch(() => false)) {
      await entrarBtn.click();
    }
  }

  await page.waitForURL(/dashboard|home/, { timeout: 30_000 });
  await expect(page).toHaveURL(/dashboard/);

  await page.context().storageState({ path: FILE });
});
