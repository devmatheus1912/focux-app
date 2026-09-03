import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('resetar senha cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/resetar_senha_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
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
    expect(screen, contains('_minPasswordLength = 8'));
    expect(screen, contains('PasswordStrengthMeter'));
    expect(screen, isNot(contains('Minimo 6 caracteres')));
    expect(screen, isNot(contains('minimo 6 caracteres')));
    expect(screen, contains('heroTeal'));
    expect(screen, contains('liveRegion: true'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('AuthStickyRoleBar'));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('resetSenhaAlterarLabel'));
    expect(screen, contains('mapResetSenhaError'));
    expect(screen, contains('form == null || !form.validate()'));
    expect(screen, contains('ensureFooter: true'));
    expect(screen, isNot(contains('debugPrint')));
    expect(screen, contains('ProductEvents.passwordResetCompleted'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('authUnfocusAndLeave'));
    expect(screen, contains('authUnfocusAndGo'));
    expect(screen, contains('AutofillHints.newPassword'));
  });
}
