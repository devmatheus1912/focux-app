import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('financeiro dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
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
    expect(screen, contains('FinanceiroResumoScreen'));
    expect(screen, contains('financeiroPanoramaExtras'));
    expect(screen, contains("'Mais no panorama'"));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FinanceiroResumoScreen'));
    expect(screen, contains('take(3)'));
    expect(screen, isNot(contains('d.zeroCta')));
    expect(screen, isNot(contains("'Abrir mensalidades'")));
    expect(screen, isNot(contains('_FinanceiroKpiGroup')));
    expect(screen, isNot(contains('ExpansionTile')));
    expect(screen, isNot(contains('PieChart')));
    expect(screen, isNot(contains('bottom: 110')));
  });
}
