import { test, expect } from '../_fixtures';

const ROTAS_ALUNO = [
  '/dashboard/aluno',
  '/aluno/perfil',
  '/aluno/ativacao',
  '/checkin/treinos',
  '/checkin/historico',
  '/feed/aluno',
  '/chat/aluno',
  '/agenda/aluno',
  '/financeiro/aluno',
  '/ia/aluno',
  '/depoimentos-aluno',
  '/gamificacao',
  '/notificacoes',
  '/suporte',
  '/perfil',
];

test.describe('@p1 smoke amplo aluno — todas as rotas', () => {
  for (const rota of ROTAS_ALUNO) {
    test(`rota ${rota} abre sem 500/layout error`, async ({ page, errors }) => {
      await page.goto(rota);
      await page.waitForLoadState('networkidle', { timeout: 30_000 });

      const fatal = errors.find((e) =>
        /BoxConstraints|RenderFlex|infinite width|never been laid out/i.test(e),
      );
      expect(fatal, `Layout error em ${rota}: ${fatal}`).toBeUndefined();
    });
  }
});
