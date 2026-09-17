import { defineConfig, devices, type Project } from '@playwright/test';
import 'dotenv/config';

const hasPersonalAuth = !!(
  process.env.E2E_PERSONAL_EMAIL?.trim() && process.env.E2E_PERSONAL_SENHA?.trim()
);
const hasAlunoAuth = !!(
  process.env.E2E_ALUNO_EMAIL?.trim() && process.env.E2E_ALUNO_SENHA?.trim()
);

if (process.env.CI) {
  if (!hasPersonalAuth) {
    console.warn(
      '[e2e] E2E_PERSONAL_EMAIL/SENHA ausentes — pulando projects auth-personal + personal',
    );
  }
  if (!hasAlunoAuth) {
    console.warn(
      '[e2e] E2E_ALUNO_EMAIL/SENHA ausentes — pulando projects auth-aluno + aluno',
    );
  }
}

const projects: Project[] = [
  ...(hasPersonalAuth
    ? ([
        { name: 'auth-personal', testMatch: /auth\.personal\.setup\.ts/ },
        {
          name: 'personal',
          testMatch: /\/personal\/.*\.spec\.ts/,
          use: {
            ...devices['Desktop Chrome'],
            storageState: '.auth/personal.json',
          },
          dependencies: ['auth-personal'],
        },
      ] as Project[])
    : []),
  ...(hasAlunoAuth
    ? ([
        { name: 'auth-aluno', testMatch: /auth\.aluno\.setup\.ts/ },
        {
          name: 'aluno',
          testMatch: /\/aluno\/.*\.spec\.ts/,
          use: {
            ...devices['Desktop Chrome'],
            storageState: '.auth/aluno.json',
          },
          dependencies: ['auth-aluno'],
        },
      ] as Project[])
    : []),
  {
    name: 'public',
    testMatch: /\/public\/.*\.spec\.ts/,
    use: { ...devices['Desktop Chrome'] },
  },
];

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
  projects,
});
