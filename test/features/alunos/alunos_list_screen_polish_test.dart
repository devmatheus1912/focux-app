import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alunos list cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alunos/screens/alunos_list_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, contains('AlunosLoadingScaffold'));
    expect(screen, contains('AlunosErrorScaffold'));
    expect(screen, contains('FocuxHubTypography'));
    expect(screen, contains('_alunosFilterChip'));
    expect(screen, contains('_AlunosListRefreshing'));
    expect(screen, contains('_displayHome'));
    expect(screen, contains('showStartPeek'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxLiquidSecondaryButton'));
    expect(screen, contains('Aplicar status'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FxGlowSurface')));
  });
}
