import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('esqueci senha cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/esqueci_senha_screen.dart',
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

    expect(screen, contains('ConsumerStatefulWidget'));
    expect(screen, contains('authRepositoryProvider'));
    expect(screen, contains('AuthRoleToggle'));
    expect(screen, contains('AuthStickyRoleBar'));
    expect(screen, contains('ensureFooter: true'));
    expect(screen, contains('LayoutBuilder'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains("params['role']"));
    expect(screen, contains("params['p']"));
    expect(screen, contains('personalSlug:'));
    expect(screen, contains('esqueciEnviarLabel'));
    expect(screen, contains('esqueciVoltarLoginLabel'));
    expect(
      screen.indexOf('esqueciEnviarLabel'),
      lessThan(screen.indexOf('esqueciVoltarLoginLabel')),
    );
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('mapEsqueciSenhaError'));
    expect(screen, contains('form == null || !form.validate()'));
    expect(screen, contains('AuthOperationalNotice'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('authUnfocusAndLeave'));
    expect(screen, contains('authUnfocusAndGo'));
    expect(screen, contains('AutofillHints.email'));
  });
}
