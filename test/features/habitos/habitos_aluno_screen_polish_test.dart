import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('habitos aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/habitos/screens/habitos_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('habitoAlunoDetailPath'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('FxKeyboardDismissScope.dismiss'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('meusHabitosPagina'));
    expect(screen, contains('Carregar mais'));
    expect(screen, isNot(contains('context.pop()')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
