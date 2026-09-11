import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('desafios aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/desafios/screens/desafios_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("safePopOrGo(context, '/dashboard/aluno')"));
    expect(screen, contains('canPop: false'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('desafioAlunoDetailPath'));
    expect(screen, contains('FeatureGate'));
    // COMUNIDADE_GRUPOS é a capability de desafios (+ grupos); não há flag separada.
    expect(screen, contains('comunidadeGrupos'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('meusPagina'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('context.pop()')));
    expect(screen, isNot(contains('FilledButton')));
  });
}
