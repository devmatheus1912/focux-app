import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('feedback aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/feedback/screens/feedback_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('listarMeus'));
    expect(screen, contains('q: _query'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('ScrollViewKeyboardDismissBehavior.onDrag'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
