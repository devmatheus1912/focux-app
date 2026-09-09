import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('notificacoes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/notificacoes/screens/notificacoes_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('notificacoesViewed'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('goPersonalShellTab'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('Buscar aviso'));
    expect(screen, contains('onTapOutside'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('Limpar busca'));
    expect(screen, contains('fxStripCardDecoration'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
  });
}
