import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('evolucao cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/evolucao/screens/evolucao_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('evolucaoHomeProvider'));
    final homeProvider = File(
      'lib/features/evolucao/providers/evolucao_home_provider.dart',
    ).readAsStringSync();
    expect(homeProvider, contains('getHome'));
    expect(homeProvider, contains('EvolucaoHomeClientCache'));
    expect(homeProvider, contains('prefetchEvolucaoHome'));
    expect(screen, contains('showFxInsetPickerSheet'));
    expect(screen, contains('IndexedStack'));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, contains('DashboardSectionHeader'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('FxHubHeader'));
    expect(screen, contains('OperationalMetricTile'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('showEvolucaoHelpSheet'));
    expect(screen, isNot(contains('TabBar')));
    expect(screen, isNot(contains('TabBarView')));
    expect(screen, isNot(contains('TabController')));
    expect(screen, isNot(contains('FloatingActionButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
