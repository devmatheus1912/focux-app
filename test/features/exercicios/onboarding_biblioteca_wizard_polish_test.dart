import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('biblioteca wizard cumpre contrato S9', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/onboarding_biblioteca_wizard.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxSettingsLayout'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('bottomNavigationBar'));
    expect(screen, contains('bibliotecaEtapaLabel'));
    expect(screen, contains('bibliotecaQuestionTitle'));
    expect(screen, contains('FocuxHubTypography.sectionTitle'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('BibliotecaWizardDraftCache'));
    expect(screen, contains('bibliotecaVoltarLabel'));
    expect(screen, contains('bibliotecaPularLabel'));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Map<String, dynamic>')));
    expect(screen, isNot(contains('ShellHeaderIconButton')));
    expect(screen, isNot(contains("icon: 'x'")));
  });

  test('biblioteca wizard opções são chips, não chevron', () {
    final steps = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/biblioteca_wizard_steps.dart',
    );
    expect(steps, contains('FxToggleChip'));
    expect(steps, contains('FxSettingsLayout.pageInset'));
    expect(steps, isNot(contains('FxSettingsTile')));
    expect(steps, isNot(contains('FxSettingsGroup')));
    expect(steps, isNot(contains('FilterChip')));
    expect(steps, isNot(contains('ChoiceChip')));
    expect(steps, isNot(contains('BibliotecaWizardActions')));
    expect(steps, isNot(contains('headlineSmall')));
    expect(steps, isNot(contains('Map<String, dynamic>')));
  });
}
