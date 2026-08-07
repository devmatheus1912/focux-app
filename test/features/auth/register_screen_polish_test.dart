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
    expect(screen, contains('heroTeal'));
    // Primário antes do secondary (hierarquia de CTA).
    expect(
      screen.indexOf('Criar minha conta'),
      lessThan(screen.indexOf('onboardingExistingAccountCta')),
    );
    expect(screen, contains('authLogoWidthFor'));
    expect(screen, contains('authScrollPadding'));
    expect(screen, contains('AuthFormEntrance'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(8));
  });
}
