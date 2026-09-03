import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('verificar codigo cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/resetar_senha_verificar_codigo_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('AuthOtpField'));
    expect(screen, contains('AuthStickyRoleBar'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('authPageTitleStyle'));
    expect(screen, contains('authSubtitleStyle'));
    expect(screen, contains('authInlineErrorStyle'));
    expect(screen, isNot(contains('fontSize: 28')));
    expect(screen, contains('liveRegion: true'));
    expect(screen, contains('resendSeconds'));
    expect(screen, isNot(contains('debugPrint')));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('resetCodigoContinuarLabel'));
    expect(screen, contains('resetCodigoEmailHint'));
    expect(screen, contains('mapResetCodigoError'));
    expect(screen, contains('form == null || !form.validate()'));
    expect(screen, contains('ensureFooter: true'));
    expect(screen, isNot(contains(r'$_email')));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('authUnfocusAndLeave'));
    expect(screen, contains('authUnfocusAndGo'));
  });
}
