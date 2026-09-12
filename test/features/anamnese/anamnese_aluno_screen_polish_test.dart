import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('anamnese aluno (preenchimento) cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/anamnese/screens/anamnese_aluno_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('FxFormStickyBar'));
    expect(screen, contains('FxFormPopGuard'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains("safePopOrGo(context, '/aluno/perfil')"));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('PAR-Q+'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('salvarMinha'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Slider(')));
  });
}
