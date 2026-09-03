import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('register cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/register_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(
      screen,
      anyOf(
        contains('friendlyError'),
        contains('DashboardErrorState'),
        contains('FxEmptyState'),
        contains('_erro'),
        contains('_TrainingEmptyState'),
        contains('ref.invalidate'),
      ),
    );
    expect(
      screen,
      anyOf(
        contains('FxLoading'),
        contains('SkeletonLoader'),
        contains('SkeletonList'),
        contains('DashboardShimmer'),
        contains('Shimmer'),
        contains('IaCopilotInsightsLoading'),
        contains('_loading'),
      ),
    );
    expect(screen, contains('BrPhone'));
    expect(screen, contains('telefone:'));
    expect(screen, contains('emailCodigo:'));
    expect(screen, contains('registerEnviarCodigoLabel'));
    expect(screen, contains('enviarCodigoEmail'));
    expect(screen, contains('mapRegisterError'));
    expect(screen, contains('mapSignupCodeError'));
    expect(screen, isNot(contains('currentState!.validate')));
    expect(screen, contains('form == null || !form.validate()'));
    expect(screen, contains('AutofillHints.oneTimeCode'));
    expect(screen, contains('heroTeal'));
    expect(screen, contains('registerCriarLabel'));
    expect(
      screen.indexOf('registerCriarLabel'),
      lessThan(screen.indexOf('onboardingExistingAccountCta')),
    );
    expect(screen, contains('AuthStickyRoleBar'));
    expect(screen, contains('ensureFooter: true'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('dark: true'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxLiquidSecondaryButton'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('PasswordStrengthMeter'));
    expect(screen, contains('GoogleSignInButton'));
    expect(screen, contains('FocuxLegal'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('authUnfocusAndLeave'));
    expect(screen, contains('authUnfocusAndGo'));
    expect(screen, contains('AutofillHints.email'));
    expect(screen, contains('AutofillHints.newPassword'));
    expect(screen, contains('FxConversionDivider'));
    expect(screen, contains('Env.googleWebClientId'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(8));
  });
}
