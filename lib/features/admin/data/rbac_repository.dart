import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class RbacRepository {
  final Dio _dio;
  RbacRepository(ApiClient client) : _dio = client.dio;

  Future<List<Map<String, dynamic>>> listarPermissoes() async {
    final r = await _dio.get('/api/rbac/permissoes');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> salvarPermissoes(Map<String, dynamic> body) async {
    await _dio.put('/api/rbac/permissoes', data: body);
  }
}
