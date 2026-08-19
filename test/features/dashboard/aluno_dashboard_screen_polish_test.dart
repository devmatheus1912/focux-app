import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('aluno dashboard cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dashboard/screens/aluno_dashboard_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(
      screen,
      anyOf(
        contains('FxContentWidthLimiter'),
        isNot(contains('constrainWidth: false')),
      ),
    );
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('deveResponder: true'));
    expect(screen, isNot(contains('invalidate(alunoRecoveryProvider)')));
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
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('useSafeArea: true')));
  });
}
