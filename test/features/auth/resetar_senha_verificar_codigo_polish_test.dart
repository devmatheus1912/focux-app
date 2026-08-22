import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('verificar codigo reset cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/resetar_senha_verificar_codigo_screen.dart',
    );
    expect(screen, anyOf(contains('fxScreenA11yScope'), contains('Semantics(')));
    expect(screen, isNot(contains('CircularProgressIndicator')));
    expect(screen, contains('AuthOtpField'));
    expect(screen, contains('AuthOtpResendTimer'));
    expect(screen, contains('validarResetCodigo'));
    expect(screen, contains('liveRegion: true'));
    expect(screen, contains('heroTeal'));
  });
}
