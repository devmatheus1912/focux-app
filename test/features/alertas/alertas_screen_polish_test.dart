import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alertas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alertas/screens/alertas_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('getHome()'));
    expect(screen, isNot(contains('Future.wait')));
  });
}
