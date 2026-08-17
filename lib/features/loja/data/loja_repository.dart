import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../models/loja_pedido.dart';

class LojaHomeBundle {
  final List<Pacote> pacotes;
  final List<LojaPedido> pedidos;

  const LojaHomeBundle({required this.pacotes, required this.pedidos});

  factory LojaHomeBundle.fromJson(Map<String, dynamic> j) {
    return LojaHomeBundle(
      pacotes:
          ((j['pacotes'] as List?) ?? const [])
              .whereType<Map>()
              .map((e) => Pacote.fromJson(Map<String, dynamic>.from(e)))
              .where((p) => p.ativo)
              .toList(),
      pedidos: LojaPedido.parseList(j['pedidos']),
    );
  }
}

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

  /// BFF tipado — first paint da tela Loja (vitrine + pedidos).
  Future<LojaHomeBundle> getHome() async {
    final response = await _dio.get('/api/loja/home');
    return LojaHomeBundle.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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
