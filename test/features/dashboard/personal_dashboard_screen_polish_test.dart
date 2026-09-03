import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('personal dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
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
    expect(screen, contains('RefreshIndicator'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
    expect(screen, contains('onboardingFromHome'));
    expect(screen, isNot(contains('onboardingStatusProvider')));
    expect(screen, contains('buildDashboardHomePrimarySlivers'));
    expect(screen, contains('DashboardPrioritiesOverlay'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('onBack:')));
    expect(screen, isNot(contains('safePopOrGo')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FxSettingsTile')));
  });
}
