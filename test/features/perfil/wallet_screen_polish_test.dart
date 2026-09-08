import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('wallet cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/perfil/screens/wallet_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, anyOf(contains('friendlyError'), contains('DashboardErrorState'), contains('FxEmptyState'), contains('_erro'), contains('_TrainingEmptyState'), contains('ref.invalidate')));
    expect(screen, anyOf(contains('FxLoading'), contains('SkeletonLoader'), contains('SkeletonList'), contains('DashboardShimmer'), contains('Shimmer'), contains('IaCopilotInsightsLoading'), contains('_loading')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
    expect(screen, contains('AlunoInsetFormField'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('FxKeyboardPopScope'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('showFxHelpSheet'));
    expect(screen, contains('AlunoSegmentedChoice'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, isNot(contains('bottomNavigationBar')));
    expect(screen, isNot(contains('FxLiquidSecondaryButton')));
    expect(screen, isNot(contains('showDialog')));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(
      screen.replaceAll('FxSatelliteListTile(', ''),
      isNot(contains('ListTile(')),
    );
    expect(screen, contains('_ResumoMensalCard'));
  });
}
