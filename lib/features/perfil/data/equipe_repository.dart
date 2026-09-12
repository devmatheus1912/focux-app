import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../models/tenant_membro.dart';

class EquipeRepository {
  EquipeRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const pageSize = 20;

  Future<Pagina<TenantMembro>> listar({
    int page = 0,
    String q = '',
    String? status,
  }) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/tenant/membros',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException(
        'GET /api/tenant/membros devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => TenantMembro.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }
}
