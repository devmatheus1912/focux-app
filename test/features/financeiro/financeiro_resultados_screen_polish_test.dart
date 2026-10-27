import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro resultados cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_resultados_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('DashboardErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('take(3)'));
    expect(screen, contains('SmartPricingCard'));
    // Panorama e Receita viraram uma tela só
    expect(screen, isNot(contains('FinanceiroResumoScreen')));
    expect(screen, isNot(contains('Mais no panorama')));
    expect(screen, isNot(contains('financeiroPanoramaExtras')));
    // Sem jargão de sigla na tela (as siglas ficam fora do texto do personal)
    for (final sigla in ['NDR', 'ARPA', 'LTV']) {
      expect(screen, isNot(contains(sigla)), reason: sigla);
    }
    // Saem de Resultados: Ativação (PQL) e Recuperação (é da Cobrança automática)
    expect(screen, isNot(contains('pqlScore')));
    expect(screen, isNot(contains('Recuperação')));
    expect(screen, isNot(contains('Ativação')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('ExpansionTile')));
    expect(screen, isNot(contains('PieChart')));
    expect(screen, contains('resultadosDetalhesVisiveis'));
  });
}
