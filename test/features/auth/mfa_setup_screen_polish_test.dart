import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('mfa setup cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/mfa_setup_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxLoading'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showMfaSetupHelpSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('mapMfaSetupError'));
    expect(screen, contains('mfaSetup'));
    expect(screen, contains('mfaConfirm'));
    expect(screen, contains('Ativar autenticador'));
    expect(screen, contains('Confirmar e ativar'));
    expect(screen, contains('Desativar MFA'));
    expect(screen, contains('QrImageView'));
    expect(screen, contains('otpauthUri'));
    expect(screen, isNot(contains('FxShellScaffold')));
  });
}
