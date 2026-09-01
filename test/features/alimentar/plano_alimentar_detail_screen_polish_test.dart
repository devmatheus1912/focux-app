import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('plano alimentar detail cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alimentar/screens/plano_alimentar_detail_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubFreshness.fromFetchedAt'));
    expect(screen, contains('showFxFormSheet'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('IaQuotaUpgrade.guardBeforeRequest'));
    expect(screen, contains('_MacroBar'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('DropdownButton')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect(screen, isNot(contains('_NovaRefeicaoSheet')));
    expect(screen, isNot(contains(r'showError(context, $e)')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
