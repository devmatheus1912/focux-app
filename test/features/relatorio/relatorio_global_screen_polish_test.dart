import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('relatorio global cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/relatorio/screens/relatorio_global_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('relatoriosHubViewed'));
    expect(screen, contains('/alunos/'));
    expect(screen, contains('/relatorio'));
    expect(screen, contains('extra:'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('Ver retenção'));
    expect(screen, contains("context.push('/retencao')"));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, contains('showRelatorioRankingCatalogSheet'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('bar-chart-2')));
    expect(screen, isNot(contains('dashboardHeroCaptionOnTeal')));
    expect(screen, isNot(contains('totalPrescritos')));
  });
}
