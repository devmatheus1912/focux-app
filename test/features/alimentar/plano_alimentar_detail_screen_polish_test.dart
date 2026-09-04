import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('plano alimentar detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alimentar/screens/plano_alimentar_detail_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showAlimentarPlanoHelpSheet'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('IaQuotaUpgrade.guardBeforeRequest'));
    expect(screen, contains('.obter('));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('FxIcon'));
    expect(
      screen,
      contains("safePopOrGo(context, '/alunos/\${widget.alunoId}/alimentar')"),
    );
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('_NovaRefeicaoSheet')));
    expect(screen, isNot(contains('PlanoAlimentarMacroHeader')));
    expect(screen, isNot(contains('PlanoAlimentarRefeicaoCard')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
