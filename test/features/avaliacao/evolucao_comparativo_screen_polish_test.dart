import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('evolucao comparativo cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/avaliacao/screens/evolucao_comparativo_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
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
    expect(screen, contains('SkeletonList'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('ShellHeaderIconButton'));
    expect(screen, contains("icon: 'message-circle'"));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('person_add')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
