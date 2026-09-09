import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('desafios cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/desafios/screens/desafios_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('Buscar desafio'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('desafioDetailPath'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('onTap: () {}')));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('comunidadeGrupos'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
