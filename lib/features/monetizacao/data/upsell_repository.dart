import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/money/fx_money.dart';
import '../../auth/providers/auth_provider.dart';

final upsellRepositoryProvider = Provider(
  (ref) => UpsellRepository(ref.read(apiClientProvider)),
);

class OfertaUpsell {
  final int id;
  final String titulo;
  final String descricao;
  final FxMoney valor;
  final String tipoGatilho;
  final bool ativo;

  /// Plano da oferta (título e valor vêm dele); nulo = "Outro valor".
  final int? pacoteId;
  final int enviadas;
  final int aceitas;

  OfertaUpsell({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.valor,
    required this.tipoGatilho,
    this.ativo = true,
    this.pacoteId,
    this.enviadas = 0,
    this.aceitas = 0,
  });

  factory OfertaUpsell.fromJson(Map<String, dynamic> j) => OfertaUpsell(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String? ?? '',
    valor: FxMoney.parse(j['valor']),
    tipoGatilho: j['tipoGatilho'] as String? ?? 'MANUAL',
    ativo: j['ativo'] as bool? ?? true,
    pacoteId: (j['pacoteId'] as num?)?.toInt(),
    enviadas: (j['enviadas'] as num?)?.toInt() ?? 0,
    aceitas: (j['aceitas'] as num?)?.toInt() ?? 0,
  );
}

/// Oferta aceita no bloco Vendas ("Julio aceitou · Treino 3 meses").
class OfertaAceita {
  const OfertaAceita({
    required this.alunoOfertaId,
    required this.alunoId,
    required this.alunoNome,
    required this.titulo,
    required this.valor,
    this.aceitaEm,
  });

  final int alunoOfertaId;
  final int alunoId;
  final String alunoNome;
  final String titulo;
  final FxMoney valor;
  final DateTime? aceitaEm;

  factory OfertaAceita.fromJson(Map<String, dynamic> j) => OfertaAceita(
    alunoOfertaId: (j['alunoOfertaId'] as num?)?.toInt() ?? 0,
    alunoId: (j['alunoId'] as num?)?.toInt() ?? 0,
    alunoNome: j['alunoNome'] as String? ?? '',
    titulo: j['titulo'] as String? ?? '',
    valor: FxMoney.parse(j['valor']),
    aceitaEm: DateTime.tryParse('${j['aceitaEm'] ?? ''}'),
  );
}

class AlunoOferta {
  final int alunoOfertaId;
  final int ofertaId;
  final String titulo;
  final String descricao;
  final FxMoney valor;
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
    valor: FxMoney.parse(j['valor']),
    status: j['status'] as String? ?? 'PENDENTE',
  );
}

class EnvioOferta {
  final int alunoOfertaId;
  final bool pushEntregue;

  const EnvioOferta({required this.alunoOfertaId, required this.pushEntregue});

  factory EnvioOferta.fromJson(Map<String, dynamic> j) => EnvioOferta(
    alunoOfertaId: (j['alunoOfertaId'] as num).toInt(),
    pushEntregue: j['pushEntregue'] as bool? ?? false,
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

  /// Ofertas aceitas, mais recentes primeiro (até 30).
  Future<List<OfertaAceita>> listarAceitas() async {
    final r = await _dio.get('/api/upsell/aceitas');
    return [
      for (final e in (r.data as List? ?? const []))
        if (e is Map) OfertaAceita.fromJson(Map<String, dynamic>.from(e)),
    ];
  }

  /// Com [pacoteId], título e valor vêm do plano no backend.
  Future<OfertaUpsell> criar({
    String titulo = '',
    required String descricao,
    Object? valor,
    String tipoGatilho = 'MANUAL',
    int? pacoteId,
  }) async {
    final r = await _dio.post(
      '/api/upsell/ofertas',
      data: {
        if (pacoteId != null) 'pacoteId': pacoteId,
        if (pacoteId == null) 'titulo': titulo,
        'descricao': descricao,
        if (pacoteId == null && valor != null)
          'valor': FxMoney.parse(valor).wire,
        'tipoGatilho': tipoGatilho,
      },
      options: ApiClient.idempotent('upsell-create'),
    );
    return OfertaUpsell.fromJson(r.data as Map<String, dynamic>);
  }

  Future<OfertaUpsell> atualizar({
    required int id,
    String? titulo,
    String? descricao,
    Object? valor,
    String? tipoGatilho,
    bool? ativo,
    int? pacoteId,
  }) async {
    final r = await _dio.patch(
      '/api/upsell/ofertas/$id',
      data: {
        if (pacoteId != null) 'pacoteId': pacoteId,
        if (titulo != null) 'titulo': titulo,
        if (descricao != null) 'descricao': descricao,
        if (valor != null) 'valor': FxMoney.parse(valor).wire,
        if (tipoGatilho != null) 'tipoGatilho': tipoGatilho,
        if (ativo != null) 'ativo': ativo,
      },
      options: ApiClient.idempotent('upsell-patch-$id'),
    );
    return OfertaUpsell.fromJson(r.data as Map<String, dynamic>);
  }

  Future<EnvioOferta> enviar({
    required int ofertaId,
    required int alunoId,
  }) async {
    final r = await _dio.post(
      '/api/upsell/ofertas/$ofertaId/enviar',
      data: {'alunoId': alunoId},
      options: ApiClient.idempotent('upsell-enviar-$ofertaId-$alunoId'),
    );
    return EnvioOferta.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> responder(int alunoOfertaId, String resposta) async {
    await _dio.post(
      '/api/upsell/aluno-oferta/$alunoOfertaId/resposta',
      queryParameters: {'resposta': resposta},
    );
  }
}
