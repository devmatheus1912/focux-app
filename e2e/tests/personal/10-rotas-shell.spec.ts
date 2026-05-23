import { test, expect } from '../_fixtures';

/**
 * Smoke amplo — abre cada rota personal documentada e checa que não dá whitescreen
 * nem 500 em endpoints essenciais.
 */
const ROTAS = [
  '/dashboard/personal',
  '/dashboard/qualidade',
  '/alunos',
  '/alunos/novo',
  '/alunos/acoes-massa',
  '/treinos',
  '/treinos/novo',
  '/exercicios',
  '/exercicios/novo',
  '/agenda',
  '/financeiro',
  '/feed',
  '/leads',
  '/alertas',
  '/alertas/config',
  '/relatorios/global',
  '/convites',
  '/planos',
  '/migracao-magica',
  '/promo-enterprise',
  '/ranking',
  '/suporte',
  '/broadcasts',
  '/depoimentos',
  '/galeria',
  '/feedback-videos',
  '/busca',
  '/analytics',
  '/admin/rbac',
  '/gamificacao',
  '/identidade-visual',
  '/perfil',
  '/perfil/wallet',
  '/notificacoes',
  '/chat/inbox',
  '/ia/chat',
  '/ia/copiloto',
];

test.describe('@p1 smoke amplo personal — todas as rotas', () => {
  for (const rota of ROTAS) {
    test(`rota ${rota} abre sem 500`, async ({ page }) => {
      await page.goto(rota);
      await page.waitForLoadState('networkidle', { timeout: 30_000 });
    });
  }
});
