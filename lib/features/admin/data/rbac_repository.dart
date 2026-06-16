import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/permissao_rbac.dart';

class RbacRepository {
  RbacRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<PermissaoRbac>> listar() async {
    final response = await _dio.get('/api/rbac/permissoes');
    return PermissaoRbac.parseList(response.data);
  }

  Future<PermissaoRbac> conceder({
    required String recurso,
    required String nivel,
  }) async {
    final response = await _dio.put(
      '/api/rbac/permissoes',
      data: {'recurso': recurso, 'nivel': nivel},
    );
    return PermissaoRbac.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> revogar(String recurso) async {
    await _dio.delete('/api/rbac/permissoes/$recurso');
  }
}
