import { test, expect } from '../_fixtures';

/**
 * P1 conhecido (status.md): "Meus treinos" do aluno quebrou com
 * "BoxConstraints forces an infinite width". Esse teste verifica que console
 * não recebe esse erro e tela carrega.
 */
test.describe('@p1 aluno meus treinos (regressão BoxConstraints)', () => {
  test('rota /checkin/treinos abre sem BoxConstraints/RenderFlex error', async ({ page, errors }) => {
    await page.goto('/checkin/treinos');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/checkin\/treinos/);

    const fatal = errors.find((e) =>
      /BoxConstraints|RenderFlex|infinite width|never been laid out/i.test(e),
    );
    expect(fatal, `Layout error detectado: ${fatal}`).toBeUndefined();
  });

  test('rota /checkin/historico abre', async ({ page }) => {
    await page.goto('/checkin/historico');
    await page.waitForLoadState('networkidle');
    await expect(page).toHaveURL(/checkin\/historico/);
  });
});
