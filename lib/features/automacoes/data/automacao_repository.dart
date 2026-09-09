import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
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

/// BFF `GET /api/automacoes/home` — fluxos + templates + planoFeatures.
class AutomacoesHomeBundle {
  final List<AutomacaoFluxo> fluxos;
  final List<AutomacaoTemplate> templates;
  final PlanoFeatures? planoFeatures;

  const AutomacoesHomeBundle({
    required this.fluxos,
    required this.templates,
    this.planoFeatures,
  });

  factory AutomacoesHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    return AutomacoesHomeBundle(
      fluxos:
          ((j['fluxos'] as List?) ?? const [])
              .map((e) => AutomacaoFluxo.fromJson(e as Map<String, dynamic>))
              .toList(),
      templates:
          ((j['templates'] as List?) ?? const [])
              .map((e) => AutomacaoTemplate.fromJson(e as Map<String, dynamic>))
              .toList(),
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
    );
  }
}

class AutomacaoRepository {
  final Dio _dio;
  AutomacaoRepository(ApiClient c) : _dio = c.dio;

  /// BFF tipado — first paint da tela Automações (fluxos + templates).
  Future<AutomacoesHomeBundle> getHome() async {
    final r = await _dio.get('/api/automacoes/home');
    return AutomacoesHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> ativarTemplate(String templateId) async {
    await _dio.post('/api/automacoes/templates/$templateId/ativar');
  }

  Future<List<AutomacaoLog>> logs(int fluxoId) async {
    final r = await _dio.get('/api/automacoes/$fluxoId/logs');
    if (r.data is! List) {
      throw const FormatException('Logs de automação inválidos');
    }
    return (r.data as List)
        .whereType<Map>()
        .map((e) => AutomacaoLog.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

class AutomacaoLog {
  final String status;
  final int passoAtual;

  const AutomacaoLog({required this.status, required this.passoAtual});

  factory AutomacaoLog.fromJson(Map<String, dynamic> j) => AutomacaoLog(
    status: j['status'] as String? ?? '',
    passoAtual: (j['passoAtual'] as num?)?.toInt() ?? 0,
  );
}
