import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('automacoes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/automacoes/screens/automacoes_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('/perfil/ferramentas'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('logs('));
    expect(screen, contains('iniciarFluxo'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('alunosHomeProvider'));
    expect(screen, contains('Carregar mais'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('Color(')));
  });
}
