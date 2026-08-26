import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('add aluno cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/alunos/screens/add_aluno_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('Outro objetivo'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('SafeArea'));
    expect(screen, contains('enabled: _canSubmit && !_loading'));
    expect(screen, contains('FxErrorState'));
    expect(screen, isNot(contains('_ErrorCard')));
    expect(screen, contains('FxSettingsGroup'));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
