import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('health dashboard cumpre contrato S1 hub Saúde', () {
    final screen = readScreenSourceBundle(
      'lib/features/health/screens/health_dashboard_screen.dart',
    );
    expect(
      screen,
      anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
    );
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('friendlyError'));
    expect(screen, contains('SaudeSkeleton'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('showBack: false'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('ProntidaoCard'));
    expect(screen, contains('SaudeMetricTile'));
    expect(screen, contains('ProntidaoTendencia'));
    expect(screen, contains('SaudeConexaoCard'));
    expect(screen, contains('SaudeDesconectadoView'));
    expect(screen, contains('Como calculamos'));
    // Atualizar é puxar para baixo: o botão de sync do topo saiu.
    expect(screen, isNot(contains('saudeAtualizarLabel')));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('saudeSyncSoftError'));
    expect(screen, contains('_syncSoftError'));
    expect(screen, contains('_SaudeSoftSyncBanner'));
    expect(screen, contains('AlwaysScrollableScrollPhysics'));
    expect(screen, contains('homeHelpOpened'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('_comoLiberar'));
    expect(screen, contains('TargetPlatform.iOS'));
    expect(screen, contains('FxErrorState'));
    expect(screen, isNot(contains('refresh-cw')));
    expect(screen, contains('_refreshing'));
    expect(screen, contains('_alterarCompartilhamento'));
    expect(screen, isNot(contains('FxHubFreshness')));
    expect(screen, isNot(contains('Google Fit')));
    expect(screen, isNot(contains('class _MetricCard')));
    expect(screen, isNot(contains('FxSettingsGroup')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });

}
