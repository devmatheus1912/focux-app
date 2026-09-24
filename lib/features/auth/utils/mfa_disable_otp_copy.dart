import '../../perfil/utils/brand_public_identity.dart';

/// Conta sem senha conhecida (Apple/Google) desliga só com o código do app ou de recuperação.
bool mfaDisablePedeSenhaOuEmail({required bool semSenhaConhecida}) =>
    !semSenhaConhecida;

String mfaDisableIntro({required bool semSenhaConhecida}) =>
    semSenhaConhecida
        ? 'Sua conta entra por Apple/Google. Basta o código do autenticador ou um código de recuperação.'
        : 'Confirme com a senha (ou um código por e-mail) e o código do autenticador.';

const mfaDisableFaltaSegundoFator =
    'Informe a senha ou peça o código por e-mail.';

/// Copy pós-envio do OTP de desativar MFA — "pedimos o envio", nunca "chegou".
String mfaDisableOtpSentMessage(String? emailMascarado) {
  final masked = (emailMascarado ?? '').trim();
  if (masked.isEmpty) {
    return 'Pedimos o envio do código para o e-mail da conta. Confira também spam/lixo eletrônico.';
  }
  if (isPrivateRelayEmail(masked)) {
    return 'Pedimos o envio para o e-mail oculto da Apple ($masked). '
        'Ele chega no e-mail real da sua conta Apple, mas a Apple às vezes bloqueia. '
        'Se não chegar em 2 minutos, fale com o suporte pelo app.';
  }
  return 'Pedimos o envio para $masked. Confira também spam/lixo eletrônico.';
}
