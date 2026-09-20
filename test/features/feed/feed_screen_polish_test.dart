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
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('viewInsetsOf'));
    expect(screen, contains('safePopOrGo'));
    expect(screen, contains('PopScope'));
    expect(screen, contains('FxHubFreshness.joinCount'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('canCompose: false'));
    expect(screen, contains('listarPersonalPagina'));
    expect(screen, contains('Carregar mais'));
    expect(screen, contains('FeedListChip'));
    expect(screen, contains('FxToggleChip'));
    expect(screen, contains('FeedPostCard'));
    expect(screen, contains('_searchFocus'));
    expect(screen, contains('FxKeyboardDismissScope'));
    expect(screen, contains('feedSparseHint'));
    expect(screen, contains('feedListBottomPad'));
    expect(screen, contains('lightbulb_outline_rounded'));
    expect(screen, isNot(contains('label: feedPublicarTileLabel')));
    expect(screen, isNot(contains('feedPublicarTileLabel()')));
    expect(screen, isNot(contains('showFxInsetPickerSheet')));
    expect(screen, isNot(contains('LengthLimitingTextInputFormatter')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, isNot(contains('FxSettingsTile')));
    expect(screen, isNot(contains('feedPublicarConfirmTitle')));
    expect(screen, contains('FeedComposerSheet'));
    expect(screen, contains('expand: true'));
    expect(screen, contains('Expanded(child: FeedComposerSheet'));
    expect(screen, isNot(contains('OutlinedButton')));
    expect(screen, isNot(contains('showModalBottomSheet')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('_FeedListHeader')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
