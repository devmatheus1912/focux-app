import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

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

class AutomacaoRepository {
  final Dio _dio;
  AutomacaoRepository(ApiClient c) : _dio = c.dio;

  Future<List<AutomacaoFluxo>> listar() async {
    final r = await _dio.get('/api/automacoes');
    return (r.data as List)
        .map((e) => AutomacaoFluxo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AutomacaoTemplate>> templates() async {
    final r = await _dio.get('/api/automacoes/templates');
    return (r.data as List)
        .map((e) => AutomacaoTemplate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> ativarTemplate(String templateId) async {
    await _dio.post('/api/automacoes/templates/$templateId/ativar');
  }

  Future<List<Map<String, dynamic>>> logs(int fluxoId) async {
    final r = await _dio.get('/api/automacoes/$fluxoId/logs');
    return (r.data as List).cast<Map<String, dynamic>>();
  }
}
