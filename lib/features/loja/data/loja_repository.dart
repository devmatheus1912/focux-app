import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../pacotes/data/pacote_repository.dart';

class LojaRepository {
  final Dio _dio;
  LojaRepository(ApiClient c) : _dio = c.dio;

  Future<List<Map<String, dynamic>>> pedidos() async {
    final r = await _dio.get('/api/loja/pedidos');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Pacote>> listarPacotes() async {
    final r = await _dio.get('/api/pacotes');
    return (r.data as List<dynamic>)
        .map((e) => Pacote.fromJson(e as Map<String, dynamic>))
        .where((p) => p.ativo)
        .toList();
  }

  Future<Map<String, dynamic>> checkout({
    required int pacoteId,
    required String buyerEmail,
    String? buyerNome,
  }) async {
    final r = await _dio.post(
      '/api/loja/checkout',
      data: {
        'pacoteId': pacoteId,
        'buyerEmail': buyerEmail,
        'buyerNome': buyerNome,
      },
    );
    return r.data as Map<String, dynamic>;
  }
}
