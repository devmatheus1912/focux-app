import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('convites cumpre contrato inset', () {
    final screen = readScreenSourceBundle(
      'lib/features/convites/screens/convites_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('getHome()'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('convitesHubViewed'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('conviteCountLabel'));
    expect(screen, contains('conviteGeradoLabel'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('ListView.builder'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('revogar'));
    expect(screen, isNot(contains('Clipboard.setData')));
    expect(screen, isNot(contains('_HeroCard')));
  });
}
