import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno activation cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/dashboard/screens/aluno_activation_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('FxWizardStickyBar'));
    expect(screen, contains('FxWizardPopGuard'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('alunoActivationProgress'));
    expect(screen, isNot(contains('_ActivationStepCard')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
