import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/financeiro/screens/financeiro_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('FxHubFreshness'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('/chat/aluno'));
    expect(screen, contains('/aluno/recorrencia'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains("'Pagas'"));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PopScope'));
    expect(screen, contains("label: 'Início'"));
    expect(screen, contains('subtitle: freshness'));
    expect(screen, contains('FocuxHubTypography.metric'));
    expect(screen, contains('showFinanceiroAlunoCobrancaSheet'));
    expect(screen, contains('circle-check'));
    expect(screen, isNot(contains('check-circle')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains('Icons.refresh')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });
}
