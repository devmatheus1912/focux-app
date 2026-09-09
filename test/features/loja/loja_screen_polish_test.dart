import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('loja cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/loja/screens/loja_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('IndexedStack'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('/perfil/ferramentas'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('TabController')));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('showFxInsetPickerSheet')));
    expect(screen, isNot(contains('Clipboard.setData')));
    expect(screen, isNot(contains('context.pop()')));
  });
}
