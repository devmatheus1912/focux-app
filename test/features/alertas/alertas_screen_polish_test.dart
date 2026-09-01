import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alertas cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/alertas/screens/alertas_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroupedList'));
    expect(screen, contains('FxEmptyState'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('RefreshIndicator'));
    expect(screen, contains('getHome()'));
    expect(screen, contains('alertasHubViewed'));
    expect(screen, isNot(contains('MOTOR ANTI-CHURN')));
    expect(screen, isNot(contains('saudaveis')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('Future.wait')));
  });
}
