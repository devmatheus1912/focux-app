import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('definir senha aluno cumpre o esqueleto S6', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/definir_senha_aluno_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('PasswordStrengthMeter'));
    expect(screen, contains('mapDefinirSenhaError'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('minLength: kDefinirSenhaMinLength'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('ScaleTransition')));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('authScrollPadding'));
    expect(screen, contains('_sairSemDefinirSenha'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('canPop: false'));
    expect(screen, contains('authUnfocusAndGo'));
    expect(screen, contains('primaryFocus?.unfocus()'));
    expect(screen, isNot(contains("authUnfocusAndLeave(context, '/login?role=aluno')")));
    expect(screen, contains('AutofillHints.newPassword'));
    expect(screen, contains('ProductEvents.passwordDefined'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(4));
  });
}
