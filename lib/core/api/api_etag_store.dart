/// Store em memória de ETags HTTP (If-None-Match → 304).
///
/// Chave = método + path normalizado (sem query de token).
///
/// Para BFFs com ClientCache (Home personal/aluno), só se envia
/// `If-None-Match` se [hasLocalBodyFor] indicar body local — evita 304 órfão.
abstract final class ApiEtagStore {
  static final Map<String, String> _etags = {};
  static final Map<String, bool Function()> _bodyProbes = {};

  static String keyFor({required String method, required String path}) {
    final normalized = path.split('?').first;
    return '${method.toUpperCase()} $normalized';
  }

  static String pathOnly(String path) => path.split('?').first;

  /// Registra se existe body no ClientCache para este path (GET home).
  static void registerBodyProbe(String path, bool Function() hasBody) {
    _bodyProbes[pathOnly(path)] = hasBody;
  }

  static bool hasLocalBodyFor(String path) {
    final probe = _bodyProbes[pathOnly(path)];
    if (probe == null) return true; // paths sem probe: etag livre
    return probe();
  }

  static bool requiresLocalBody(String path) =>
      _bodyProbes.containsKey(pathOnly(path));

  static String? get(String key) => _etags[key];

  static void put(String key, String etag) {
    final t = etag.trim();
    if (t.isEmpty) return;
    _etags[key] = t;
  }

  static void remove(String key) => _etags.remove(key);

  static void removeForPath({required String method, required String path}) {
    remove(keyFor(method: method, path: path));
  }

  static void clear() => _etags.clear();
}
