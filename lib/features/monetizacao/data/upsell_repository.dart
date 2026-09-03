import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class OfertaUpsell {
  final int id;
  final String titulo;
  final String descricao;
  final double valor;
  final String tipoGatilho;
  final bool ativo;

  OfertaUpsell({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.tipoGatilho,
    this.ativo = true,
  });

  factory OfertaUpsell.fromJson(Map<String, dynamic> j) => OfertaUpsell(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String? ?? '',
    valor: (j['valor'] as num?)?.toDouble() ?? 0,
    tipoGatilho: j['tipoGatilho'] as String? ?? 'MANUAL',
    ativo: j['ativo'] as bool? ?? true,
  );
}

class AlunoOferta {
  final int alunoOfertaId;
  final int ofertaId;
  final String titulo;
  final String descricao;
  final double valor;
  final String status;

  AlunoOferta({
    required this.alunoOfertaId,
    required this.ofertaId,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.status,
  });

  factory AlunoOferta.fromJson(Map<String, dynamic> j) => AlunoOferta(
    alunoOfertaId: (j['alunoOfertaId'] as num).toInt(),
    ofertaId: (j['ofertaId'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String? ?? '',
    valor: (j['valor'] as num?)?.toDouble() ?? 0,
    status: j['status'] as String? ?? 'PENDENTE',
  );
}

class UpsellRepository {
  final Dio _dio;
  UpsellRepository(ApiClient c) : _dio = c.dio;

  Future<List<OfertaUpsell>> listarOfertas() async {
    final r = await _dio.get('/api/upsell/ofertas');
    return (r.data as List<dynamic>)
        .map((e) => OfertaUpsell.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OfertaUpsell> criar({
    required String titulo,
    required String descricao,
    required double valor,
    String tipoGatilho = 'TRILHA_CONCLUIDA',
  }) async {
    final r = await _dio.post(
      '/api/upsell/ofertas',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'valor': valor,
        'tipoGatilho': tipoGatilho,
      },
      options: ApiClient.idempotent(
        'upsell-create-$titulo-$valor-$tipoGatilho',
      ),
    );
    return OfertaUpsell.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertaUpsell> atualizar({
    required int id,
    String? titulo,
    String? descricao,
    double? valor,
    String? tipoGatilho,
    bool? ativo,
  }) async {
    final r = await _dio.patch(
      '/api/upsell/ofertas/$id',
      data: {
        if (titulo != null) 'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        if (valor != null) 'valor': valor,
        if (tipoGatilho != null) 'tipoGatilho': tipoGatilho,
        if (ativo != null) 'ativo': ativo,
      },
      options: ApiClient.idempotent('upsell-patch-$id'),
    );
    return OfertaUpsell.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<AlunoOferta>> listarMeusPendentes() async {
    final r = await _dio.get('/api/upsell/me/pendentes');
    return (r.data as List<dynamic>)
        .map((e) => AlunoOferta.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> responder(int alunoOfertaId, String resposta) async {
    await _dio.post(
      '/api/upsell/aluno-oferta/$alunoOfertaId/resposta',
      queryParameters: {'resposta': resposta},
    );
  }
}
