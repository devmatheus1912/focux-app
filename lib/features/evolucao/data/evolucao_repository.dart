import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class MedidaCorporal {
  final int id;
  final String data;
  final double? peso, cintura, quadril, braco;
  final String? fotoUrl;
  MedidaCorporal({
    required this.id,
    required this.data,
    this.peso,
    this.cintura,
    this.quadril,
    this.braco,
    this.fotoUrl,
  });
  factory MedidaCorporal.fromJson(Map<String, dynamic> j) => MedidaCorporal(
    id: j['id'] as int,
    data: j['data'] as String,
    peso: (j['peso'] as num?)?.toDouble(),
    cintura: (j['cintura'] as num?)?.toDouble(),
    quadril: (j['quadril'] as num?)?.toDouble(),
    braco: (j['braco'] as num?)?.toDouble(),
    fotoUrl: j['fotoUrl'] as String?,
  );
}

class RecordePessoal {
  final int id;
  final int exercicioId;
  final String exercicioNome;
  final String data;
  final double? cargaKg;
  final int? repeticoes;
  RecordePessoal({
    required this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.data,
    this.cargaKg,
    this.repeticoes,
  });
  factory RecordePessoal.fromJson(Map<String, dynamic> j) => RecordePessoal(
    id: j['id'] as int,
    exercicioId: j['exercicioId'] as int,
    exercicioNome: j['exercicioNome'] as String,
    data: j['data'] as String,
    cargaKg: (j['cargaKg'] as num?)?.toDouble(),
    repeticoes: j['repeticoes'] as int?,
  );
}

class EventoEngajamento {
  final String tipo, descricao;
  final String dataHora;
  EventoEngajamento({
    required this.tipo,
    required this.descricao,
    required this.dataHora,
  });
  factory EventoEngajamento.fromJson(Map<String, dynamic> j) =>
      EventoEngajamento(
        tipo: j['tipo'] as String,
        descricao: j['descricao'] as String,
        dataHora: j['dataHora'] as String,
      );
}

/// BFF `GET /api/alunos/{id}/evolucao/home` — medidas + recordes.
class EvolucaoHomeBundle {
  final List<MedidaCorporal> medidas;
  final List<RecordePessoal> recordes;

  const EvolucaoHomeBundle({required this.medidas, required this.recordes});

  factory EvolucaoHomeBundle.fromJson(Map<String, dynamic> j) {
    return EvolucaoHomeBundle(
      medidas:
          ((j['medidas'] as List?) ?? const [])
              .map((e) => MedidaCorporal.fromJson(e as Map<String, dynamic>))
              .toList(),
      recordes:
          ((j['recordes'] as List?) ?? const [])
              .map((e) => RecordePessoal.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}

class EvolucaoRepository {
  final Dio _dio;
  EvolucaoRepository(ApiClient c) : _dio = c.dio;

  /// First paint da tela Evolução — um round-trip (medidas + recordes).
  Future<EvolucaoHomeBundle> getHome(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/evolucao/home');
    return EvolucaoHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<MedidaCorporal>> listarMinhasMedidas() async {
    final r = await _dio.get('/api/aluno/medidas');
    return (r.data as List).map((e) => MedidaCorporal.fromJson(e)).toList();
  }

  Future<MedidaCorporal> adicionarMinhaMedida({
    String? data,
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
    String? fotoUrl,
  }) async {
    final r = await _dio.post(
      '/api/aluno/medidas',
      data: {
        'data': data ?? DateTime.now().toIso8601String().substring(0, 10),
        if (peso != null) 'peso': peso,
        if (cintura != null) 'cintura': cintura,
        if (quadril != null) 'quadril': quadril,
        if (braco != null) 'braco': braco,
        if (fotoUrl != null && fotoUrl.isNotEmpty) 'fotoUrl': fotoUrl,
      },
    );
    return MedidaCorporal.fromJson(r.data);
  }

  Future<List<MedidaCorporal>> listarMedidas(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/medidas');
    return (r.data as List).map((e) => MedidaCorporal.fromJson(e)).toList();
  }

  Future<MedidaCorporal> adicionarMedida(
    int alunoId, {
    String? data,
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
  }) async {
    final r = await _dio.post(
      '/api/alunos/$alunoId/medidas',
      data: {
        'data': data ?? DateTime.now().toIso8601String().substring(0, 10),
        if (peso != null) 'peso': peso,
        if (cintura != null) 'cintura': cintura,
        if (quadril != null) 'quadril': quadril,
        if (braco != null) 'braco': braco,
      },
    );
    return MedidaCorporal.fromJson(r.data);
  }

  Future<List<RecordePessoal>> listarRecordes(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/recordes');
    return (r.data as List).map((e) => RecordePessoal.fromJson(e)).toList();
  }

  Future<RecordePessoal> adicionarRecorde(
    int alunoId, {
    required String exercicioNome,
    double? carga,
    String? unidade,
    String? observacao,
  }) async {
    final r = await _dio.post(
      '/api/alunos/$alunoId/recordes',
      data: {
        'exercicioNome': exercicioNome,
        if (carga != null) 'carga': carga,
        if (unidade != null) 'unidade': unidade,
        if (observacao != null && observacao.isNotEmpty)
          'observacao': observacao,
      },
    );
    return RecordePessoal.fromJson(r.data);
  }

  Future<List<EventoEngajamento>> engajamento(
    int alunoId, {
    int dias = 30,
  }) async {
    final r = await _dio.get(
      '/api/alunos/$alunoId/engajamento',
      queryParameters: {'dias': dias},
    );
    final data = r.data;
    final eventos =
        data is Map ? (data['eventos'] as List?) ?? [] : data as List;
    return eventos
        .map((e) => EventoEngajamento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> engajamentoResumo(int alunoId) async {
    final r = await _dio.get('/api/alunos/$alunoId/engajamento');
    final data = r.data;
    if (data is Map<String, dynamic>) return data;
    // Se vier como lista, retorna mapa vazio para não quebrar a UI
    return {};
  }

  Future<void> compartilharEvolucao(int alunoId) async {
    await _dio.post('/api/alunos/$alunoId/evolucao/compartilhar');
  }
}
