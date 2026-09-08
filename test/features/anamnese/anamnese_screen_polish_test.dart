import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('anamnese personal (revisão) cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/anamnese/screens/anamnese_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('solicitar'));
    expect(screen, contains('revisar'));
    expect(screen, isNot(contains("put('/api/alunos/\$alunoId/anamnese'")));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showAnamneseHelpSheet'));
    expect(screen, contains("'Solicitar anamnese'"));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Slider(')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('anamnese aluno (preenchimento) cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/anamnese/screens/anamnese_aluno_screen.dart',
    );
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('PAR-Q+'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('salvarMinha'));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Slider(')));
  });
}
