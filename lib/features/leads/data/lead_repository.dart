import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Lead {
  final int id;
  final String nome;
  final String? telefone;
  final String? origem;
  final String? objetivo;
  final String? observacoes;
  final String status;
  final String criadoEm;
  final String? convertidoEm;
  final String? proximoContato;

  Lead({
    required this.id,
    required this.nome,
    this.telefone,
    this.origem,
    this.objetivo,
    this.observacoes,
    required this.status,
    required this.criadoEm,
    this.convertidoEm,
    this.proximoContato,
  });

  factory Lead.fromJson(Map<String, dynamic> j) => Lead(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String,
    telefone: j['telefone'] as String?,
    origem: j['origem'] as String?,
    objetivo: j['objetivo'] as String?,
    observacoes: j['observacoes'] as String?,
    status: j['status'] as String,
    criadoEm: (j['criadoEm'] as String).substring(0, 10),
    convertidoEm:
        j['convertidoEm'] != null
            ? (j['convertidoEm'] as String).substring(0, 10)
            : null,
    proximoContato:
        j['proximoContato'] != null
            ? (j['proximoContato'] as String).substring(0, 10)
            : null,
  );
}

class LeadInteracao {
  final int id;
  final int leadId;
  final String tipo;
  final String descricao;
  final String? dataInteracao;

  LeadInteracao({
    required this.id,
    required this.leadId,
    required this.tipo,
    required this.descricao,
    this.dataInteracao,
  });

  factory LeadInteracao.fromJson(Map<String, dynamic> j) => LeadInteracao(
    id: (j['id'] as num).toInt(),
    leadId: (j['leadId'] as num).toInt(),
    tipo: j['tipo'] as String,
    descricao: j['descricao'] as String,
    dataInteracao: j['dataInteracao'] as String?,
  );
}

class LeadRepository {
  final Dio _dio;
  LeadRepository(ApiClient c) : _dio = c.dio;

  Future<List<Lead>> listar({String? status}) async {
    final r = await _dio.get(
      '/api/leads',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (r.data as List)
        .map((e) => Lead.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Lead> criar({
    required String nome,
    String? telefone,
    String? origem,
    String? objetivo,
    String? observacoes,
  }) async {
    final r = await _dio.post(
      '/api/leads',
      data: {
        'nome': nome,
        if (telefone != null && telefone.isNotEmpty) 'telefone': telefone,
        if (origem != null && origem.isNotEmpty) 'origem': origem,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (observacoes != null && observacoes.isNotEmpty)
          'observacoes': observacoes,
      },
    );
    return Lead.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Lead> atualizar(int id, Map<String, dynamic> data) async {
    final r = await _dio.put('/api/leads/$id', data: data);
    return Lead.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Lead> atualizarProximoContato(int id, String data) async {
    return atualizar(id, {'proximoContato': data});
  }

  Future<void> arquivar(int id) async {
    await _dio.delete('/api/leads/$id');
  }

  Future<void> converter(int id) async {
    await _dio.post('/api/leads/$id/converter');
  }

  Future<List<LeadInteracao>> listarInteracoes(int leadId) async {
    final r = await _dio.get('/api/leads/$leadId/interacoes');
    return (r.data as List)
        .map((j) => LeadInteracao.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<LeadInteracao> adicionarInteracao(
    int leadId,
    String tipo,
    String descricao,
  ) async {
    final r = await _dio.post(
      '/api/leads/$leadId/interacoes',
      data: {'tipo': tipo, 'descricao': descricao},
    );
    return LeadInteracao.fromJson(r.data as Map<String, dynamic>);
  }
}
