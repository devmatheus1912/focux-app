import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../planos/data/planos_repository.dart';

class AutomacaoFluxo {
  final int id;
  final String nome;
  final String? descricao;
  final String triggerTipo;
  final bool ativo;
  final String? templateId;

  AutomacaoFluxo({
    required this.id,
    required this.nome,
    required this.triggerTipo,
    required this.ativo,
    this.descricao,
    this.templateId,
  });

  factory AutomacaoFluxo.fromJson(Map<String, dynamic> j) => AutomacaoFluxo(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String? ?? '',
    descricao: j['descricao'] as String?,
    triggerTipo: j['triggerTipo'] as String? ?? '',
    ativo: j['ativo'] as bool? ?? false,
    templateId: j['templateId'] as String?,
  );

  AutomacaoFluxo copyWith({bool? ativo}) => AutomacaoFluxo(
    id: id,
    nome: nome,
    descricao: descricao,
    triggerTipo: triggerTipo,
    ativo: ativo ?? this.ativo,
    templateId: templateId,
  );
}

class AutomacaoTemplate {
  final String id;
  final String nome;
  final String descricao;
  final String triggerTipo;

  AutomacaoTemplate({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.triggerTipo,
  });

  factory AutomacaoTemplate.fromJson(Map<String, dynamic> j) =>
      AutomacaoTemplate(
        id: j['id'] as String? ?? '',
        nome: j['nome'] as String? ?? '',
        descricao: j['descricao'] as String? ?? '',
        triggerTipo: j['triggerTipo'] as String? ?? '',
      );
}

/// BFF `GET /api/automacoes/home` — fluxos paginados + templates + planoFeatures.
class AutomacoesHomeBundle {
  final List<AutomacaoFluxo> fluxos;
  final List<AutomacaoTemplate> templates;
  final PlanoFeatures? planoFeatures;
  final int page;
  final bool hasNext;
  final int totalFluxos;

  const AutomacoesHomeBundle({
    required this.fluxos,
    required this.templates,
    this.planoFeatures,
    this.page = 0,
    this.hasNext = false,
    this.totalFluxos = 0,
  });

  factory AutomacoesHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    final fluxos =
        ((j['fluxos'] as List?) ?? const [])
            .map((e) => AutomacaoFluxo.fromJson(e as Map<String, dynamic>))
            .toList();
    return AutomacoesHomeBundle(
      fluxos: fluxos,
      templates:
          ((j['templates'] as List?) ?? const [])
              .map((e) => AutomacaoTemplate.fromJson(e as Map<String, dynamic>))
              .toList(),
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
      page: (j['page'] as num?)?.toInt() ?? 0,
      hasNext: j['hasNext'] == true,
      totalFluxos: (j['totalFluxos'] as num?)?.toInt() ?? fluxos.length,
    );
  }
}

class AutomacaoRepository {
  final Dio _dio;
  AutomacaoRepository(ApiClient c) : _dio = c.dio;

  static const pageSize = 20;

  /// BFF tipado — first paint da tela Automações (fluxos + templates).
  Future<AutomacoesHomeBundle> getHome({int page = 0, String q = ''}) async {
    final query = q.trim();
    final r = await _dio.get(
      '/api/automacoes/home',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return AutomacoesHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> ativarTemplate(String templateId) async {
    await _dio.post('/api/automacoes/templates/$templateId/ativar');
  }

  Future<Pagina<AutomacaoLog>> logs(int fluxoId, {int page = 0}) async {
    final r = await _dio.get(
      '/api/automacoes/$fluxoId/logs',
      queryParameters: {'page': page, 'size': pageSize},
    );
    final data = r.data;
    if (data is! Map) {
      throw const FormatException(
        'GET /api/automacoes/{id}/logs devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => AutomacaoLog.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<void> iniciarFluxo({
    required int fluxoId,
    required int alunoId,
  }) async {
    await _dio.post('/api/automacoes/$fluxoId/iniciar/$alunoId');
  }

  Future<AutomacaoFluxo> pausar(int fluxoId) async {
    final r = await _dio.post('/api/automacoes/$fluxoId/pause');
    return AutomacaoFluxo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<AutomacaoFluxo> retomar(int fluxoId) async {
    final r = await _dio.post('/api/automacoes/$fluxoId/resume');
    return AutomacaoFluxo.fromJson(r.data as Map<String, dynamic>);
  }
}

class AutomacaoLog {
  final String status;
  final int passoAtual;
  final String? iniciadoEm;
  final String? erro;
  final int entregasOk;
  final int entregasFalha;

  const AutomacaoLog({
    required this.status,
    required this.passoAtual,
    this.iniciadoEm,
    this.erro,
    this.entregasOk = 0,
    this.entregasFalha = 0,
  });

  factory AutomacaoLog.fromJson(Map<String, dynamic> j) => AutomacaoLog(
    status: j['status'] as String? ?? '',
    passoAtual: (j['passoAtual'] as num?)?.toInt() ?? 0,
    iniciadoEm: j['iniciadoEm'] as String?,
    erro: j['erro'] as String?,
    entregasOk: (j['entregasOk'] as num?)?.toInt() ?? 0,
    entregasFalha: (j['entregasFalha'] as num?)?.toInt() ?? 0,
  );
}
