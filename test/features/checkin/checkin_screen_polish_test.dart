import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('checkin cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/checkin/screens/checkin_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('_sair'));
    expect(screen, contains('_abrirFila'));
    expect(screen, contains('_currentExercise'));
    expect(screen, contains('useMesh: false'));
    expect(screen, contains('Finalizar treino'));
    expect(screen, isNot(contains('CheckinLiveCoachingCard')));
    expect(screen, isNot(contains('CheckinLiveBadge')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

  test('checkin header é S8 sem badge ao vivo', () {
    final header = readScreenSourceBundle(
      'lib/features/checkin/widgets/checkin_header_widgets.dart',
    );
    expect(header, contains("child: const Text('Sair')"));
    expect(header, isNot(contains('CheckinLiveBadge')));
    expect(header, isNot(contains('AO VIVO')));
    expect(header, isNot(contains('chevron_left')));
  });
}
