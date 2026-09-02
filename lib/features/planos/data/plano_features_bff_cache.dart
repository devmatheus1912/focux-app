import 'planos_repository.dart';

/// Snapshot in-memory de entitlements vindos de qualquer BFF `/home` ou `me`.
/// TTL alinhado ao Home (90s). Não substitui o disco — só evita GET `/api/planos/me`.
abstract final class PlanoFeaturesBffCache {
  static const ttl = Duration(seconds: 90);

  static PlanoFeatures? _features;
  static DateTime? _savedAt;

  static PlanoFeatures? getIfFresh({DateTime? now}) {
    final features = _features;
    final at = _savedAt;
    if (features == null || at == null) return null;
    final age = (now ?? DateTime.now()).difference(at);
    if (age > ttl) return null;
    return features;
  }

  static void put(PlanoFeatures features, {DateTime? now}) {
    _features = features;
    _savedAt = now ?? DateTime.now();
  }

  static void clear() {
    _features = null;
    _savedAt = null;
  }
}
