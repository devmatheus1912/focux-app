import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../models/loja_pedido.dart';

class LojaRepository {
  LojaRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<LojaPedido>> pedidos() async {
    final response = await _dio.get('/api/loja/pedidos');
    return LojaPedido.parseList(response.data);
  }

  Future<List<Pacote>> listarPacotes() async {
    final response = await _dio.get('/api/pacotes');
    return (response.data as List<dynamic>)
        .map((e) => Pacote.fromJson(e as Map<String, dynamic>))
        .where((p) => p.ativo)
        .toList();
  }

  Future<LojaCheckoutResult> checkout({
    required int pacoteId,
    required String buyerEmail,
    String? buyerNome,
  }) async {
    final response = await _dio.post(
      '/api/loja/checkout',
      data: {
        'pacoteId': pacoteId,
        'buyerEmail': buyerEmail,
        'buyerNome': buyerNome,
      },
    );
    return LojaCheckoutResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
