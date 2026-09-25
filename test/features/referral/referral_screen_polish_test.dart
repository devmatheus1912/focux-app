import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('referral cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/referral/screens/referral_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxStripCard'));
    expect(screen, contains('FxActionChip'));
    expect(screen, contains('Copiar convite'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains("safePopOrGo(context, '/perfil')"));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('referralLinkShared'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('Não conseguimos carregar a indicação'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('FilledButton')));
  });
}
