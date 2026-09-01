import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('biblioteca wizard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/exercicios/screens/onboarding_biblioteca_wizard.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'x'"));
    expect(screen, contains('FxSettingsLayout'));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FilterChip')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('Map<String, dynamic>')));
  });

  test('biblioteca wizard fold segue pele do Perfil', () {
    final steps = readScreenSourceBundle(
      'lib/features/exercicios/screens/widgets/biblioteca_wizard_steps.dart',
    );
    expect(steps, contains('FxSettingsGroup'));
    expect(steps, contains('FxSettingsTile'));
    expect(steps, contains('FxSettingsLayout.pageInset'));
    expect(steps, contains('minHeight: 4'));
    expect(steps, isNot(contains('FilterChip')));
    expect(steps, isNot(contains('ChoiceChip')));
    expect(steps, isNot(contains('FxLiquidPrimaryButton')));
    expect(steps, isNot(contains('headlineSmall')));
    expect(steps, isNot(contains('Map<String, dynamic>')));
  });
}
