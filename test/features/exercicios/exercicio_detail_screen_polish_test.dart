import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('exercicio detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/exercicios/screens/exercicio_detail_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxConversionTextLink'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('exerciseVideoUploadConfirmTitle'));
    expect(screen, contains('exerciseVideoRemoveConfirmTitle'));
    expect(screen, contains('exerciseVideoUploadSuccess'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, isNot(contains('ExerciseVideoUploadStrip')));
    expect(screen, contains('_PrescriptionReadinessPanel'));
    expect(screen, contains('_VideoPlayer'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showExercicioDetailHelpSheet'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('exercicioHubSubtitle'));
    expect(screen, contains("name: 'star'"));
    expect(screen, contains('exercicioVideoMetric'));
    expect(screen, contains("label: 'Biblioteca'"));
    expect(screen, contains('PopScope'));
  });
}
