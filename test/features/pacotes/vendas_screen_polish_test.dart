import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Vendas (11/11): uma tela, sem abas, em grupos; "Plano" como palavra única.
void main() {
  test('vendas cumpre contrato e o redesign', () {
    final screen = readScreenSourceBundle(
      'lib/features/pacotes/screens/vendas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("'Sua página'"));
    expect(screen, contains("'Planos à venda'"));
    expect(screen, contains("'Ofertas para alunos'"));
    expect(screen, contains("'Vendas'"));
    expect(screen, contains("'Ver como o cliente vê'"));
    expect(screen, contains('showPlanoSheet'));
    expect(screen, contains('showOfertaUpsellEditor'));
    expect(screen, contains('showFxGroupedActionSheet'));
    expect(screen, contains("'/financeiro?alunoId="));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('Vitrine')));
    expect(screen, isNot(contains("'Pacotes'")), reason: 'na tela é "Plano"');
    expect(screen, isNot(contains("'Novo pacote'")));
  });
}
