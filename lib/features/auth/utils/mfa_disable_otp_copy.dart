import '../../perfil/utils/brand_public_identity.dart';

/// Copy pós-envio do OTP de desativar MFA.
String mfaDisableOtpSentMessage(String? emailMascarado) {
  final masked = (emailMascarado ?? '').trim();
  if (masked.isEmpty) {
    return 'Código enviado para o e-mail da conta. Confira também spam/lixo eletrônico.';
  }
  if (isPrivateRelayEmail(masked)) {
    return 'Código enviado para o e-mail oculto da Apple ($masked). '
        'Abra o Mail da conta Apple (não só o Gmail) e confira spam.';
  }
  return 'Código enviado para $masked. Confira também spam/lixo eletrônico.';
}
