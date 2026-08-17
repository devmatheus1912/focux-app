import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('ia copiloto cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/ia/screens/ia_copiloto_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('ia copiloto usa estados canônicos e mantém o disclaimer', () {
    final screen = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('IaCopilotSafetyNote'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('iaCopilotoHomeProvider'));
    expect(screen, contains("retryLabel:"));
  });
}
