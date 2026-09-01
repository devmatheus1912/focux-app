import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('dunning ops cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/dunning/screens/dunning_ops_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FeatureGate'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('dunningHubViewed'));
    expect(screen, contains('circle-check'));
    expect(screen, isNot(contains('check-circle')));
    expect(screen, isNot(contains('Aluno #')));
    expect(screen, isNot(contains('FxSatellitePanel')));
    expect(screen, isNot(contains('FxSatelliteListTile')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FilledButton')));
  });
}
