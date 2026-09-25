import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('referral cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/referral/screens/referral_screen.dart',
    );
    final body = File(
      'lib/features/referral/widgets/referral_body.dart',
    ).readAsStringSync();
    final hub = '$screen\n$body';
    expect(screen, contains('fxScreenA11yScope'));
    expect(hub, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(body, contains('OperationalMetricTile'));
    expect(body, contains('FxStripCard'));
    expect(body, contains('FxActionChip'));
    expect(body, contains('l10n.referralCopyInvite'));
    expect(hub, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains("safePopOrGo(context, '/perfil')"));
    expect(hub, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('copySensitiveToClipboard'));
    expect(screen, contains('referralLinkShared'));
    expect(screen, contains('referralViewed'));
    expect(body, contains('keyboardDismissBehavior'));
    expect(screen, contains('l10n.referralLoadErrorTitle'));
    expect(hub, isNot(contains('TabBar')));
    expect(hub, isNot(contains('FloatingActionButton')));
    expect(hub, isNot(contains('FilledButton')));
  });

  test('regra comercial nunca fica fixa no app', () {
    final dir = Directory('lib/features/referral');
    final fontes = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    expect(fontes, isNot(contains('30 dias')));
    expect(fontes, isNot(contains('20%')));
    expect(fontes, isNot(contains('90 dias')));
  });
}
