import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('onboarding cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
  });

  test('onboarding de uma tela por perfil, no desenho do login', () {
    final screen = readScreenSourceBundle(
      'lib/features/onboarding/screens/onboarding_screen.dart',
    );
    expect(screen, contains('AuthShell'));
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('AuthFraseComLink'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('_persistPersona'));
    // sem carrossel, sem "Pular" nem "Quero isso"
    expect(screen, isNot(contains('PageView')));
    expect(screen, isNot(contains('PageController')));
    expect(screen, isNot(contains('TextButton')));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('FxSettingsGroup')));
  });
}
