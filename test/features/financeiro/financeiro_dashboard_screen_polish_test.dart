import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/financeiro/screens/financeiro_dashboard_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, isNot(contains('FxSettingsGroup')));
  });
}
