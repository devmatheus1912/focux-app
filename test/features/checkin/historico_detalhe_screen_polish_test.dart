import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('historico detalhe cumpre contrato S3', () {
    final screen = readScreenSourceBundle(
      'lib/features/checkin/screens/historico_detalhe_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, isNot(contains('FxHubHeader')));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: false'));
    expect(screen, isNot(contains('emphasize: true')));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('historicoStickyLabel'));
    expect(screen, contains("safePopOrGo(context, '/checkin/historico')"));
    expect(screen, contains("'/checkin/executar'"));
    expect(screen, contains('detalhe(widget.execucaoId)'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('DashboardHomeActionChip')));
    expect(screen, contains('HistoricoDetalheMemCache'));
    expect(screen, contains('FxLoading.sectionShimmer'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('historicoSeriesFeitasEfetivas'));
    expect(screen, contains('historicoEmptySeriesFromExercicios'));
    expect(screen, contains('historicoVolumeHint'));
    expect(screen, isNot(contains('EagleTokens.warn')));
    expect(screen, contains('historicoStatusDisplayLabel'));
    expect(screen, contains('historicoSessaoMetricsFromExecucao'));
    expect(screen, contains('evolucaoSessao'));
    expect(screen, contains("label: 'Volume'"));
    expect(screen, contains("label: 'Séries'"));
    // Sinal vive no caption do hero (não mais tile KPI).
    expect(screen, contains('metrics.sinalLabel'));
    expect(screen, isNot(contains("label: 'Sinal'")));
    expect(screen, contains('FxSparkline'));
    expect(screen, isNot(contains('freshness: freshness')));
    expect(screen, contains('historicoDuracaoLabel'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('Treino não encontrado'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FocuxMicrocopy.naoFoiPossivelCarregar'));
    expect(screen, contains('historicoDetalheSecoes'));
    expect(screen, contains('historicoSecaoNotas'));
    expect(screen, contains('historicoNotaLine'));
    expect(screen, contains('evolucoesCarga'));
    expect(screen, contains('checkinCargaLabel'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FloatingActionButton')));
  });
}
