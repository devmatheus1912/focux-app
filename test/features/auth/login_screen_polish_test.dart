import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('login cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/login_screen.dart',
    );
    final shell = readScreenSourceBundle(
      'lib/features/auth/widgets/auth_shell.dart',
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
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));

    expect(screen, contains('loginEsqueciPath'));
    expect(screen, contains('loginRegisterPath'));
    expect(
      readScreenSourceBundle('lib/features/auth/utils/login_display.dart'),
      contains("Uri.encodeComponent(slug)"),
    );

    // Lockup de marca compartilhado — largura única para Personal e Aluno.
    expect(screen, contains('AuthLoginBrandHeader'));
    expect(shell, contains('AuthFormEntrance'));
    expect(shell, contains('coloredDepthGlow'));
    expect(shell, contains('TokensStrip.glassPanel'));
    expect(shell, contains('AppTheme.buildDarkTheme'));
    expect(shell, isNot(contains('fxStripCardDecoration')));
    expect(screen, contains('authScrollPadding'));
    expect(
      readScreenSourceBundle('lib/features/auth/utils/auth_layout.dart'),
      contains('kAuthFormLogoWidth = 118.0'),
    );

    // Segurança: nunca logar token/conta do Google no console.
    expect(screen, isNot(contains('debugPrint')));
    expect(screen, isNot(contains('idToken.length')));

    // Google aluno exige tenant (?p=slug).
    expect(screen, contains("_personalSlug"));
    expect(screen, contains('PERSONAL_SLUG_REQUIRED'));

    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('ProductEvents.loginSuccess'));
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('GoogleSignInButton'));
    expect(screen, contains('AppleSignInButton'));
    expect(screen, contains('_submitApple'));
    expect(screen, contains('appleSignInEnabled'));
    expect(screen, contains('!Platform.isIOS'));
    expect(screen, contains('AuthField'));
    expect(screen, contains('LayoutBuilder'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('AutofillHints.email'));
    expect(screen, contains('AutofillHints.password'));
    expect(screen, contains('authUnfocusAndGo'));
    expect(screen, contains('FxConversionDivider'));
    expect(shell, contains('FxKeyboardPopScope'));
    expect(
      readScreenSourceBundle('lib/features/auth/widgets/auth_field.dart'),
      contains('onTapOutside'),
    );
  });
}
