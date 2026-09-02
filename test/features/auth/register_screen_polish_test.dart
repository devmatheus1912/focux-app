import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('register cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/register_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
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
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('PasswordStrengthMeter'));
    expect(screen, contains('GoogleSignInButton'));
    expect(screen, contains('FocuxLegal'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(8));
  });
}
