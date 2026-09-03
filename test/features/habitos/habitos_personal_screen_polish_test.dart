import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('habitos personal cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/habitos/screens/habitos_personal_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('habitCoaching'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
