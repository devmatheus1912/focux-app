import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('register aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/auth/screens/register_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(
      screen.indexOf('Criar conta'),
      lessThan(screen.indexOf('authInviteExistingAccountCta')),
    );
    expect(screen, contains('AuthStickyRoleBar'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('FxConversionLockup'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('minLength: 8'));
    expect(screen, contains('Mín. 8 caracteres'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
