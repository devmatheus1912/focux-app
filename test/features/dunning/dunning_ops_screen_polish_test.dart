import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('dunning ops cumpre contrato Tier S+', () {
    final screen = [
      readScreenSourceBundle(
        'lib/features/dunning/screens/dunning_ops_screen.dart',
      ),
      readScreenSourceBundle(
        'lib/features/dunning/widgets/dunning_focus_card.dart',
      ),
      readScreenSourceBundle(
        'lib/features/dunning/widgets/dunning_acoes_sheet.dart',
      ),
    ].join('\n');
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('emphasize: true'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('dunningHubViewed'));
    expect(screen, contains('showDunningCatalogSheet'));
    expect(screen, contains('showDunningAcoesSheet'));
    expect(screen, contains('Escrever'));
    expect(screen, contains('Cobrar'));
    expect(screen, contains('Ver mais'));
    expect(screen, contains('alunoNome'));
    expect(screen, contains('circle-check'));
    expect(screen, isNot(contains('check-circle')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains('aluno_id')));
    expect(screen, isNot(contains('FxSatellitePanel')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FilledButton')));
  });
}
