import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('health dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/health/screens/health_dashboard_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
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
    expect(screen, contains('showBack: false'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('Prontidão'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('saudeAtualizarLabel'));
    expect(screen, contains('AlwaysScrollableScrollPhysics'));
    expect(screen, contains('homeHelpOpened'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, isNot(contains('class _MetricCard')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
