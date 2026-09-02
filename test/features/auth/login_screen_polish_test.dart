import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('login cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/login_screen.dart');
    final shell = readScreenSourceBundle('lib/features/auth/widgets/auth_shell.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
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

    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('ProductEvents.loginSuccess'));
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('GoogleSignInButton'));
    expect(screen, contains('AuthField'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('AuthTextLink')));
  });
}
