import '../../../core/api/api_client.dart';
import 'ferramentas_catalogo_cache.dart';
import 'ferramentas_catalogo_models.dart';

class FerramentasCatalogoRepository {
  FerramentasCatalogoRepository(this._client);

  final ApiClient _client;

  /// Busca o BFF e atualiza o cache. Se `version` mudou, invalida o anterior.
  Future<FerramentasCatalogo> fetch({bool allowStaleOnError = true}) async {
    try {
      final r = await _client.dio.get('/api/personal/ferramentas/catalogo');
      final data = r.data;
      if (data is! Map) {
        throw FormatException(
          'GET /api/personal/ferramentas/catalogo devolve objeto, não lista.',
        );
      }
      final map = Map<String, dynamic>.from(data);
      final catalogo = FerramentasCatalogo.fromJson(map);
      await FerramentasCatalogoCache.invalidateIfVersionChanged(catalogo.version);
      await FerramentasCatalogoCache.save(catalogo, map);
      return catalogo;
    } catch (e) {
      if (!allowStaleOnError) rethrow;
      final stale = await FerramentasCatalogoCache.load();
      if (stale != null) return stale;
      rethrow;
    }
  }

  Future<FerramentasCatalogo?> peekCache() => FerramentasCatalogoCache.load();
}
