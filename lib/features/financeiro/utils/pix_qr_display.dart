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

/// Prefer copia-e-cola for a scannable QR; fall back to MP image bytes.
bool pixQrHasRenderablePayload({
  required String? pixCopiaECola,
  required String? qrCodeBase64,
}) {
  final copia = pixCopiaECola?.trim() ?? '';
  if (copia.isNotEmpty) return true;
  return decodePixQrBase64(qrCodeBase64) != null;
}
