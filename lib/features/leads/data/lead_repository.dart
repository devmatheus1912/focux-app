import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../../planos/data/planos_repository.dart';

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

  Future<Lead> buscar(int id) async {
    final r = await _dio.get('/api/leads/$id');
    return Lead.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Pagina<Lead>> listarPagina({
    String? status,
    String? q,
    int page = 0,
    int size = 20,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/leads',
      queryParameters: {
        'page': page,
        'size': size,
        if (status != null && status.trim().isNotEmpty) 'status': status,
        if (query.isNotEmpty) 'q': query,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException('GET /api/leads devolve Pagina, não lista crua.');
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => Lead.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<List<Lead>> listar({String? status}) async {
    return (await listarPagina(status: status, page: 0, size: 100)).content;
  }

  /// BFF tipado — first paint do Funil de Leads (mesmo SSOT de [listar]).
  Future<LeadsHomeBundle> getHome() async {
    final r = await _dio.get('/api/leads/home');
    return LeadsHomeBundle.fromJson(r.data as Map<String, dynamic>);
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

class LeadsHomeBundle {
  final List<Lead> leads;
  final PlanoFeatures? planoFeatures;

  LeadsHomeBundle({required this.leads, this.planoFeatures});

  factory LeadsHomeBundle.fromJson(Map<String, dynamic> j) {
    final planoRaw = j['planoFeatures'];
    return LeadsHomeBundle(
      leads:
          ((j['leads'] as List?) ?? const [])
              .map((e) => Lead.fromJson(e as Map<String, dynamic>))
              .toList(),
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
    );
  }
}
