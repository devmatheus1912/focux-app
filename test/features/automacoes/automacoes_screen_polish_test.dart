import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('automacoes cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/automacoes/screens/automacoes_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
  });

  test('templates card keeps Ativar from crushing title text', () {
    final screen = readScreenSourceBundle(
      'lib/features/automacoes/screens/automacoes_screen.dart',
    );
    expect(screen, contains('Expanded('));
    expect(screen, contains("child: const Text('Ativar')"));
    expect(screen, isNot(contains('trailing: FilledButton')));
  });
}
