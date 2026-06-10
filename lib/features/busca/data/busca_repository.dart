import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class BuscaRepository {
  final Dio _dio;
  BuscaRepository(ApiClient client) : _dio = client.dio;

  Future<List<Map<String, dynamic>>> buscar(String query) async {
    final r = await _dio.get('/api/busca', queryParameters: {'q': query});
    return (r.data as List).cast<Map<String, dynamic>>();
  }
}
