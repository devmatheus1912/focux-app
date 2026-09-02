import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/utils/reset_senha_display.dart';

void main() {
  test('copy da nova senha exige código e confirma sessão', () {
    expect(resetSenhaAlterarLabel(), 'Alterar senha');
    expect(resetSenhaHasNonce('abc'), isTrue);
    expect(resetSenhaHasNonce(''), isFalse);
    expect(resetSenhaSubtitle(hasNonce: true), contains('validado'));
    expect(resetSenhaConfirmMessage(), contains('sessões'));
  });
}
