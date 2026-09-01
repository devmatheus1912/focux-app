import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('alertas config cumpre contrato inset', () {
    final screen = readScreenSourceBundle(
      'lib/features/alertas/screens/alertas_config_screen.dart',
    );
    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('FxErrorState'));
    expect(screen, contains('SkeletonList'));
    expect(screen, contains('alertasConfigViewed'));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('Icons.calendar_month')));
  });
}
