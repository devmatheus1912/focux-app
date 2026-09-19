import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

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
    id: (j['id'] as num?)?.toInt() ?? 0,
    data: _medidaDataString(j['data']),
    peso: (j['peso'] as num?)?.toDouble(),
    cintura: (j['cintura'] as num?)?.toDouble(),
    quadril: (j['quadril'] as num?)?.toDouble(),
    braco: (j['braco'] as num?)?.toDouble(),
    fotoUrl: j['fotoUrl'] as String?,
  );
}

String _medidaDataString(Object? raw) {
  if (raw is String) return raw;
  if (raw is List && raw.length >= 3) {
    final y = raw[0];
    final m = raw[1];
    final d = raw[2];
    return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }
  if (raw is Map) {
    final y = raw['year'];
    final m = raw['month'];
    final d = raw['day'];
    if (y != null && m != null && d != null) {
      return '$y-${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
    }
  }
  return raw?.toString() ?? '';
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
    id: (j['id'] as num?)?.toInt() ?? 0,
    exercicioId: (j['exercicioId'] as num?)?.toInt() ?? 0,
    exercicioNome: j['exercicioNome'] as String? ?? '',
    data: _medidaDataString(j['data']),
    cargaKg: (j['cargaKg'] as num?)?.toDouble(),
    repeticoes: (j['repeticoes'] as num?)?.toInt(),
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
              .map(
                (e) => MedidaCorporal.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
      recordes:
          ((j['recordes'] as List?) ?? const [])
              .map(
                (e) => RecordePessoal.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
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

  Future<MedidaCorporal> adicionarMedida(
    int alunoId, {
    String? data,
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
  }) async {
    final payloadData =
        data ?? DateTime.now().toIso8601String().substring(0, 10);
    final r = await _dio.post(
      '/api/alunos/$alunoId/medidas',
      data: {
        'data': payloadData,
        if (peso != null) 'peso': peso,
        if (cintura != null) 'cintura': cintura,
        if (quadril != null) 'quadril': quadril,
        if (braco != null) 'braco': braco,
      },
    );
    final raw = r.data;
    if (raw is Map) {
      try {
        return MedidaCorporal.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        // POST já persistiu — shape da resposta não pode mascarar sucesso.
      }
    }
    return MedidaCorporal(
      id: 0,
      data: payloadData,
      peso: peso,
      cintura: cintura,
      quadril: quadril,
      braco: braco,
    );
  }

  Future<RecordePessoal> adicionarRecorde(
    int alunoId, {
    required String exercicioNome,
    double? carga,
    int? repeticoes,
  }) async {
    final r = await _dio.post(
      '/api/alunos/$alunoId/recordes',
      data: {
        'exercicioNome': exercicioNome,
        'data': DateTime.now().toIso8601String().substring(0, 10),
        if (carga != null) 'cargaKg': carga,
        if (repeticoes != null) 'repeticoes': repeticoes,
      },
    );
    final raw = r.data;
    if (raw is Map) {
      try {
        return RecordePessoal.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {}
    }
    return RecordePessoal(
      id: 0,
      exercicioId: 0,
      exercicioNome: exercicioNome,
      data: DateTime.now().toIso8601String().substring(0, 10),
      cargaKg: carga,
      repeticoes: repeticoes,
    );
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

  Future<Pagina<FotoEvolucao>> listarFotosPagina(
    int alunoId, {
    int page = 0,
  }) async {
    final r = await _dio.get(
      '/api/alunos/$alunoId/fotos',
      queryParameters: {'page': page, 'size': 20},
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/alunos/$alunoId/fotos devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => FotoEvolucao.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<void> adicionarFoto(
    int alunoId, {
    required List<int> bytes,
    required String filename,
  }) async {
    final fd = FormData.fromMap({
      'foto': MultipartFile.fromBytes(bytes, filename: filename),
    });
    await _dio.post('/api/alunos/$alunoId/fotos', data: fd);
  }
}

class FotoEvolucao {
  final int id;
  final String url;
  final String data;

  const FotoEvolucao({
    required this.id,
    required this.url,
    required this.data,
  });

  factory FotoEvolucao.fromJson(Map<String, dynamic> j) => FotoEvolucao(
    id: (j['id'] as num?)?.toInt() ?? 0,
    url: j['url'] as String? ?? j['fotoUrl'] as String? ?? '',
    data: j['data'] as String? ?? j['createdAt'] as String? ?? '',
  );
}
