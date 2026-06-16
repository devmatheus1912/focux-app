import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/tenant_membro.dart';

class EquipeRepository {
  EquipeRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<TenantMembro>> listar() async {
    final response = await _dio.get('/api/tenant/membros');
    return TenantMembro.parseList(response.data);
  }

  Future<void> convidar({required String email}) async {
    await _dio.post(
      '/api/tenant/membros',
      data: {'userEmail': email, 'role': 'ASSISTENTE'},
    );
  }
}
