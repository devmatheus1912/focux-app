import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('feed cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/feed/screens/feed_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxShellAppBar'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxSettingsTile'));
    expect(screen, contains('feedPublicarConfirmTitle'));
    expect(screen, contains('LengthLimitingTextInputFormatter'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('OutlinedButton')));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('_FeedListHeader')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
