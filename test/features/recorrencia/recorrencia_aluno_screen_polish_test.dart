import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('recorrencia aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/recorrencia/screens/recorrencia_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('recorrenciaAlunoStickyLabel'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('recorrenciaValorLabel'));
    expect(screen, contains('recorrenciaProximaValue'));
    expect(screen, contains('pausarMinha'));
    expect(screen, contains('retomarMinha'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('/chat/aluno'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('FilledButton')));
    // Um nome só, um cartão e um botão; sem atalhos soltos.
    expect(screen, isNot(contains('OperationalMetricTile')));
    expect(screen, isNot(contains('FxHubHeader')));
    expect(screen, isNot(contains('FxActionChip')));
    expect(screen, isNot(contains("'Assinatura'")));
    expect(screen, contains("'Pagamento automático'"));
    expect(screen, contains('recorrenciaFormaLabel'));
  });
}
