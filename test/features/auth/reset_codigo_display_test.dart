import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/reset_codigo_display.dart';

void main() {
  test('mascara e-mail e monta path da nova senha', () {
    expect(resetCodigoContinuarLabel(), 'Continuar');
    expect(resetCodigoEmailHint('ana@studio.com'), 'a***@studio.com');
    expect(resetCodigoEmailHint(''), 'seu e-mail');
    expect(
      resetCodigoNovaSenhaPath(nonce: 'abc', isAluno: false),
      '/resetar-senha?resetNonce=abc&role=personal',
    );
  });
}
