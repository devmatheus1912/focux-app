import '../../../core/api/api_client.dart';
import '../models/busca_global_models.dart';

/// Busca global — fetch fora da UI (parse na borda API → model tipado).
class BuscaRepository {
  BuscaRepository(this._api);

  final ApiClient _api;

  Future<BuscaGlobalResult> buscar(String query) async {
    final res = await _api.dio.get(
      '/api/busca',
      queryParameters: {'q': query},
    );
    return BuscaGlobalResult.fromJson(res.data as Map<String, dynamic>);
  }
}
