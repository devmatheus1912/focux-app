import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('copilot actions cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/dashboard/screens/copilot_actions_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, isNot(contains('showFxInsetPickerSheet')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('BrandPalette.softened'));
    expect(screen, isNot(contains('BrandPalette.accent')));
    expect(screen, contains('_CopilotTaskCard'));
    expect(screen, contains('_RadarSignalCard'));
    expect(screen, contains('Buscar tarefa'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('onTapOutside'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('_StatusSegmentedControl')));
    expect(screen, isNot(contains('_MiniActionButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
