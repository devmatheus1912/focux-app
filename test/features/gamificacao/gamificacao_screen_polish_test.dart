import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('gamificacao cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/gamificacao/screens/gamificacao_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('FilledButton')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('gamificacaoPersonalEmptyTitle'));
    expect(screen, contains('gamificacaoRotaDoBadge'));
    expect(screen, contains('userRoleProvider'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
