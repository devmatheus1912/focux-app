import { defineConfig, devices } from '@playwright/test';
import 'dotenv/config';

export default defineConfig({
  testDir: './tests',
  outputDir: './test-results',
  timeout: 90_000,
  expect: { timeout: 15_000 },
  fullyParallel: false,
  retries: process.env.CI ? 2 : 1,
  workers: 1,
  reporter: [
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['list'],
    ['json', { outputFile: 'test-results/results.json' }],
  ],
  use: {
    baseURL: process.env.E2E_BASE_URL ?? 'http://localhost:61791',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    headless: !!process.env.CI,
    actionTimeout: 15_000,
    navigationTimeout: 30_000,
    locale: 'pt-BR',
    timezoneId: 'America/Sao_Paulo',
    // Force accessibility tree → Flutter Web (CanvasKit) auto-enables
    // semantics on boot so Playwright can see/click widgets.
    launchOptions: {
      args: ['--force-renderer-accessibility'],
    },
  },
  projects: [
    { name: 'auth-personal', testMatch: /auth\.personal\.setup\.ts/ },
    { name: 'auth-aluno',    testMatch: /auth\.aluno\.setup\.ts/ },

    {
      name: 'personal',
      testMatch: /\/personal\/.*\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        storageState: '.auth/personal.json',
      },
      dependencies: ['auth-personal'],
    },
    {
      name: 'aluno',
      testMatch: /\/aluno\/.*\.spec\.ts/,
      use: {
        ...devices['Desktop Chrome'],
        storageState: '.auth/aluno.json',
      },
      dependencies: ['auth-aluno'],
    },
    {
      name: 'public',
      testMatch: /\/public\/.*\.spec\.ts/,
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
