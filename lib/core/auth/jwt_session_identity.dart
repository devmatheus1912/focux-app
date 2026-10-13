import 'dart:convert';

/// Quem é o dono do access JWT (`sub` + tenant), sem validar assinatura.
abstract final class JwtSessionIdentity {
  JwtSessionIdentity._();

  static String? of(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
        allowMalformed: true,
      );
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      final sub = map['sub'];
      if (sub is! String || sub.isEmpty) return null;
      return '$sub|${map['personal_id']}';
    } catch (_) {
      return null;
    }
  }

  /// Token novo de outra conta (ou ilegível): o cache local da anterior não pode vazar.
  static bool isDifferentAccount(String? previous, String next) {
    if (previous == null || previous.isEmpty) return false;
    final antes = of(previous);
    return antes == null || antes != of(next);
  }
}
