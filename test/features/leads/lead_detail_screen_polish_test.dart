import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('lead detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/leads/screens/lead_detail_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('PopupMenuButton')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
  });
}
