import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('treinos list cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/treinos_list_screen.dart',
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
  });

  test('treinos list usa estados canônicos da Home', () {
    final screen = readScreenSourceBundle(
      'lib/features/treinos/screens/treinos_list_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('class _TreinosErrorState')));
    expect(screen, isNot(contains('class _EmptyState')));
    expect(screen, isNot(contains('class _NoResultsState')));
    expect(screen, contains('ProductEvents.treinosViewed'));
    expect(screen, contains('ProductEvents.treinosHelpOpened'));
  });
}
