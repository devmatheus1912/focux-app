import { test as setup, expect } from '@playwright/test';
import 'dotenv/config';
import { mkdirSync } from 'node:fs';
import { enableFlutterSemantics } from './_fixtures';

const FILE = '.auth/aluno.json';
const BASE_URL = process.env.E2E_BASE_URL ?? 'http://localhost:61791';

setup('autentica aluno', async ({ page }) => {
  mkdirSync('.auth', { recursive: true });

  const email = process.env.E2E_ALUNO_EMAIL?.trim();
  const senha = process.env.E2E_ALUNO_SENHA?.trim();
  setup.skip(!email || !senha, 'Set E2E_ALUNO_EMAIL and E2E_ALUNO_SENHA in .env');
  if (!email || !senha) return;

  await page.goto(`${BASE_URL}/#/login`);
  await page.waitForLoadState('domcontentloaded');
  await page.waitForTimeout(2500);
  await enableFlutterSemantics(page);
  await page.waitForTimeout(800);

  // Try multiple ways to find and click the Aluno toggle
  const candidates = [
    page.getByRole('button', { name: /^Aluno$/ }),
    page.locator('[aria-label="Aluno"]'),
    page.locator('flt-semantics[aria-label="Aluno"]'),
    page.locator('flt-semantics:has-text("Aluno")'),
    page.getByText(/^Aluno$/),
  ];

  let clicked = false;
  for (const loc of candidates) {
    try {
      await loc.first().click({ timeout: 3000 });
      clicked = true;
      break;
    } catch {}
  }

  if (!clicked) {
    // last resort: click coordinate of right half of the toggle in the form
    // Form is centered; toggle is roughly at y=290 on default 1280x720 viewport
    const vp = page.viewportSize() ?? { width: 1280, height: 720 };
    const x = vp.width / 2 + 60;
    const y = 290;
    await page.mouse.click(x, y);
    console.warn(`Aluno toggle clicked by coordinate (${x},${y}) — fragile fallback`);
  }

  await page.waitForTimeout(500);

  // Now type credentials via Tab order (works even without semantics)
  await page.locator('body').click({ position: { x: 5, y: 5 } });
  await page.waitForTimeout(300);

  const inputs = page.locator('input:not([type="checkbox"]):not([type="hidden"])');
  const count = await inputs.count();

  if (count >= 2) {
    await inputs.nth(0).click();
    await page.keyboard.type(email, { delay: 30 });
    await inputs.nth(1).click();
    await page.keyboard.type(senha, { delay: 30 });
  } else {
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.type(email, { delay: 30 });
    await page.keyboard.press('Tab');
    await page.keyboard.type(senha, { delay: 30 });
  }

  await page.keyboard.press('Enter');
  await page.waitForTimeout(800);

  if (!/aluno|definir-senha/.test(page.url())) {
    const entrarBtn = page.getByText(/^Entrar$/).first();
    if (await entrarBtn.isVisible().catch(() => false)) {
      await entrarBtn.click();
    }
  }

  await page.waitForURL(/aluno|definir-senha/, { timeout: 30_000 });

  if (page.url().includes('definir-senha')) {
    throw new Error('Aluno test account requires password change. Use a stable account.');
  }

  await expect(page).toHaveURL(/aluno/);
  await page.context().storageState({ path: FILE });
});
