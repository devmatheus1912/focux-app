import 'dart:convert';
import 'dart:typed_data';

/// Strips an optional `data:image/...;base64,` prefix and decodes MP QR bytes.
Uint8List? decodePixQrBase64(String? raw) {
  if (raw == null) return null;
  var s = raw.trim();
  if (s.isEmpty) return null;
  final marker = s.indexOf('base64,');
  if (marker >= 0) {
    s = s.substring(marker + 'base64,'.length).trim();
  }
  try {
    return base64Decode(s);
  } catch (_) {
    return null;
  }
}

const pixChaveAusenteCodigo = 'PIX_CHAVE_AUSENTE';

const pixSemCodigoErro = 'Não foi possível montar o código PIX. Tente de novo.';

const pixAvisarPagamentoLabel = 'Já paguei, avisar personal';

const pixAvisoEnviadoMensagem =
    'Avisamos seu personal. Ele confirma assim que ver no banco.';

String pixDestinoHint({required bool asAluno}) =>
    asAluno
        ? 'O valor vai direto para a conta do seu personal. Depois de pagar, avise para ele confirmar.'
        : 'O valor cai direto na sua conta. Confira no banco e toque em Marcar paga.';

/// Prefer copia-e-cola for a scannable QR; fall back to MP image bytes.
bool pixQrHasRenderablePayload({
  required String? pixCopiaECola,
  required String? qrCodeBase64,
}) {
  final copia = pixCopiaECola?.trim() ?? '';
  if (copia.isNotEmpty) return true;
  return decodePixQrBase64(qrCodeBase64) != null;
}
