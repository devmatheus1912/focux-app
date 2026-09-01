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
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('getHome()'));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('convitesHubViewed'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('Clipboard.setData')));
    expect(screen, isNot(contains('_HeroCard')));
  });
}
