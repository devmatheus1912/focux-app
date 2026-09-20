import 'dart:convert';

/// Lê `exp` do access JWT sem validar assinatura (só para refresh proativo no cliente).
abstract final class JwtAccessExp {
  JwtAccessExp._();

  static DateTime? expiresAt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload =
          utf8.decode(base64Url.decode(normalized), allowMalformed: true);
      final map = jsonDecode(payload);
      if (map is! Map) return null;
      final exp = map['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      if (exp is num) {
        return DateTime.fromMillisecondsSinceEpoch(
          exp.toInt() * 1000,
          isUtc: true,
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// true se já expirou ou falta menos que [skew].
  static bool isExpiringSoon(
    String jwt, {
    Duration skew = const Duration(minutes: 5),
    DateTime? now,
  }) {
    final exp = expiresAt(jwt);
    if (exp == null) return false;
    final clock = (now ?? DateTime.now()).toUtc();
    return !clock.isBefore(exp.subtract(skew));
  }

  static bool isExpired(String jwt, {DateTime? now}) {
    final exp = expiresAt(jwt);
    if (exp == null) return false;
    final clock = (now ?? DateTime.now()).toUtc();
    return !clock.isBefore(exp);
  }
}
