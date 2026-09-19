import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('progressao aceitar cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/ia/screens/progressao_aceitar_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
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
    expect(screen, contains('backgroundColor: primary'));
    expect(screen, contains("label: const Text('Aceitar')"));
    expect(screen, contains('FocuxHubTypography'));
    expect(screen, isNot(contains('backgroundColor: EagleTokens.good')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
