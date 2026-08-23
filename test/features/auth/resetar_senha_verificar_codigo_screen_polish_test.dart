import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  test('verificar codigo cumpre contrato Tier S+', () {
    final screen = readScreenSourceBundle(
      'lib/features/auth/screens/resetar_senha_verificar_codigo_screen.dart',
    );

    expect(screen, contains('fxScreenA11yScope'));
    expect(screen, contains('AuthShell'));
    expect(screen, contains('AuthFormEntrance'));
    expect(screen, contains('AuthOtpField'));
    expect(screen, isNot(contains('CircularProgressIndicator')));

    // Tipografia canônica — sem fontSize literal na tela.
    expect(screen, contains('authPageTitleStyle'));
    expect(screen, contains('authSubtitleStyle'));
    expect(screen, contains('authInlineErrorStyle'));
    expect(screen, isNot(contains('fontSize: 28')));

    // Erro anunciado para leitor de tela e reenvio com countdown.
    expect(screen, contains('liveRegion: true'));
    expect(screen, contains('resendSeconds'));

    // Segurança: não logar código nem nonce.
    expect(screen, isNot(contains('debugPrint')));
  });
}
