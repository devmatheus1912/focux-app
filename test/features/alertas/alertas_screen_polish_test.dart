import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alertas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alertas/screens/alertas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('constrainWidth: false'));
    expect(screen, contains('FxContentWidthLimiter'));
    expect(screen, contains('Como calculamos'));
    expect(screen, contains('keyboardDismissBehavior'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSatelliteListTile'));
    expect(screen, isNot(contains('FxSettingsGroupedList')));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('getHome()'));
    expect(screen, contains('/alertas/config'));
    expect(screen, contains('alertasHubViewed'));
    expect(screen, contains('alertaAdiarCtaLabel'));
    expect(screen, contains('FxLiquidPrimaryButton'));
    expect(screen, contains('Enviar mensagem'));
    expect(screen, isNot(contains("fxIcon: 'message-circle'")));
    expect(screen, isNot(contains('MOTOR ANTI-CHURN')));
    expect(screen, isNot(contains('saudaveis')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('Future.wait')));
  });
}
