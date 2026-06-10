import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class GrowthRepository {
  final Dio _dio;
  GrowthRepository(ApiClient client) : _dio = client.dio;

  Future<Map<String, dynamic>> quotaMigracaoFoto() async {
    final r = await _dio.get('/api/v1/migracao/foto/quota');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> recapSocial(int alunoId) async {
    final r = await _dio.get('/api/v1/social/recap/$alunoId');
    return r.data as Map<String, dynamic>;
  }
}
