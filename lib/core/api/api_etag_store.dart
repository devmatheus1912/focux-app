/// Store em memória de ETags HTTP (If-None-Match → 304).
///
/// Chave = método + path normalizado (sem query de token).
abstract final class ApiEtagStore {
  static final Map<String, String> _etags = {};

  static String keyFor({required String method, required String path}) {
    final normalized = path.split('?').first;
    return '${method.toUpperCase()} $normalized';
  }

  static String? get(String key) => _etags[key];

  static void put(String key, String etag) {
    final t = etag.trim();
    if (t.isEmpty) return;
    _etags[key] = t;
  }

  static void clear() => _etags.clear();

  static void remove(String key) => _etags.remove(key);
}
