import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../pacotes/data/pacote_repository.dart';
import '../../planos/data/planos_repository.dart';
import '../models/loja_pedido.dart';

class LojaHomeBundle {
  final List<Pacote> pacotes;
  final List<LojaPedido> pedidos;
  final PlanoFeatures? planoFeatures;
  final int pacotesPage;
  final bool pacotesHasNext;
  final int pacotesTotal;
  final int pedidosPage;
  final bool pedidosHasNext;
  final int pedidosTotal;

  const LojaHomeBundle({
    required this.pacotes,
    required this.pedidos,
    this.planoFeatures,
    this.pacotesPage = 0,
    this.pacotesHasNext = false,
    this.pacotesTotal = 0,
    this.pedidosPage = 0,
    this.pedidosHasNext = false,
    this.pedidosTotal = 0,
  });

  factory LojaHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    final pacotes =
        ((j['pacotes'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Pacote.fromJson(Map<String, dynamic>.from(e)))
            .where((p) => p.ativo)
            .toList();
    final pedidos = LojaPedido.parseList(j['pedidos']);
    return LojaHomeBundle(
      pacotes: pacotes,
      pedidos: pedidos,
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
      pacotesPage: (j['pacotesPage'] as num?)?.toInt() ?? 0,
      pacotesHasNext: j['pacotesHasNext'] == true,
      pacotesTotal: (j['pacotesTotal'] as num?)?.toInt() ?? pacotes.length,
      pedidosPage: (j['pedidosPage'] as num?)?.toInt() ?? 0,
      pedidosHasNext: j['pedidosHasNext'] == true,
      pedidosTotal: (j['pedidosTotal'] as num?)?.toInt() ?? pedidos.length,
    );
  }
}

class LojaRepository {
  LojaRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  static const pageSize = 20;

  Future<Pagina<LojaPedido>> pedidos({int page = 0, String q = ''}) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/loja/pedidos',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException(
        'GET /api/loja/pedidos devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => LojaPedido.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Pagina<Pacote>> listarPacotes({int page = 0, String q = ''}) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/pacotes',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('GET /api/pacotes devolve Pagina, não lista crua.');
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Pacote.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  /// BFF tipado — first paint da tela Loja (vitrine + pedidos).
  Future<LojaHomeBundle> getHome({
    String q = '',
    int pacotesPage = 0,
    int pedidosPage = 0,
  }) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/loja/home',
      queryParameters: {
        'pacotesPage': pacotesPage,
        'pedidosPage': pedidosPage,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
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

  Future<LojaPedido> confirmar(int pedidoId) async {
    final response = await _dio.post('/api/loja/pedidos/$pedidoId/confirmar');
    return LojaPedido.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
