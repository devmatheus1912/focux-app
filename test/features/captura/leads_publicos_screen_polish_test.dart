import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('leads publicos cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/captura/screens/leads_publicos_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('/leads'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('leadPublicoStickyLabel'));
    expect(screen, contains('_clearFiltros'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('.meus('));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('context.pop()')));
  });
}
