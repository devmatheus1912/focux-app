import '../../perfil/utils/brand_public_identity.dart';

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
