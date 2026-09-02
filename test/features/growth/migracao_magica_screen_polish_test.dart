import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('migracao magica cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle('lib/features/growth/screens/migracao_magica_screen.dart');
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('FxShellScaffold'));
    expect(screen, anyOf(contains('FxContentWidthLimiter'), isNot(contains('constrainWidth: false'))));
    expect(screen, contains('FxSettingsGroup'));
    expect(screen, contains('showFxConfirmSheet'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, contains('migracaoIniciarLabel'));
    expect(screen, isNot(contains('FxLiquidPrimaryButton')));
    expect(screen, isNot(contains('OutlinedButton')));
    expect('Colors.'.allMatches(screen).length, lessThanOrEqualTo(16));
  });
}
