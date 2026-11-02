import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import 'meta_corporal.dart';

class MedidaCorporal {
  final int id;
  final String data;
  final double? peso, cintura, quadril, braco;
  final String? fotoUrl;

  /// ALUNO ou PERSONAL. Nulo em medida antiga.
  final String? registradoPor;
  MedidaCorporal({
    required this.id,
    required this.data,
    this.peso,
    this.cintura,
    this.quadril,
    this.braco,
    this.fotoUrl,
    this.registradoPor,
  });
  factory MedidaCorporal.fromJson(Map<String, dynamic> j) => MedidaCorporal(
    id: (j['id'] as num?)?.toInt() ?? 0,
    data: _medidaDataString(j['data']),
    peso: (j['peso'] as num?)?.toDouble(),
    cintura: (j['cintura'] as num?)?.toDouble(),
    quadril: (j['quadril'] as num?)?.toDouble(),
    braco: (j['braco'] as num?)?.toDouble(),
    fotoUrl: j['fotoUrl'] as String?,
    registradoPor: j['registradoPor'] as String?,
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

  /// Só em TREINO. Backend antigo não manda: aí vale o texto de [descricao].
  final String? status;

  /// Só em MENSAGEM: ALUNO ou PERSONAL.
  final String? remetente;

  EventoEngajamento({
    required this.tipo,
    required this.descricao,
    required this.dataHora,
    this.status,
    this.remetente,
  });
  factory EventoEngajamento.fromJson(Map<String, dynamic> j) =>
      EventoEngajamento(
        tipo: j['tipo'] as String,
        descricao: j['descricao'] as String,
        dataHora: j['dataHora'] as String,
        status: j['status'] as String?,
        remetente: j['remetente'] as String?,
      );
}

/// Aderência sobre o previsto na ficha. `percent` nulo: começando ou sem ficha.
class AderenciaResumo {
  const AderenciaResumo({
    this.percent,
    this.feitos = 0,
    this.previstos = 0,
    this.comecando = false,
    this.diasDescanso = const [],
    this.diaDaFicha = 0,
  });

  final int? percent;
  final int feitos;
  final int previstos;
  final bool comecando;

  /// 1 (segunda) a 7 (domingo).
  final List<int> diasDescanso;

  /// Dias desde o início da ficha, contando hoje.
  final int diaDaFicha;

  factory AderenciaResumo.fromJson(Map<String, dynamic> j) => AderenciaResumo(
    percent: (j['percent'] as num?)?.toInt(),
    feitos: (j['feitos'] as num?)?.toInt() ?? 0,
    previstos: (j['previstos'] as num?)?.toInt() ?? 0,
    comecando: j['comecando'] as bool? ?? false,
    diasDescanso:
        ((j['diasDescanso'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
    diaDaFicha: (j['diaDaFicha'] as num?)?.toInt() ?? 0,
  );
}

/// Os três anéis da Evolução. Campo nulo: anel vazio.
class EvolucaoAneis {
  const EvolucaoAneis({
    this.treinoFeitos = 0,
    this.treinoPrevistos,
    this.metaProgresso,
    this.ultimaMedida,
    this.cicloMedidasDias = 30,
  });

  final int treinoFeitos;

  /// Dias por semana da ficha. Nulo sem ficha.
  final int? treinoPrevistos;

  /// De 0 a 100, a meta aberta mais avançada. Nulo sem meta.
  final int? metaProgresso;
  final String? ultimaMedida;
  final int cicloMedidasDias;

  factory EvolucaoAneis.fromJson(Map<String, dynamic> j) => EvolucaoAneis(
    treinoFeitos: (j['treinoFeitos'] as num?)?.toInt() ?? 0,
    treinoPrevistos: (j['treinoPrevistos'] as num?)?.toInt(),
    metaProgresso: (j['metaProgresso'] as num?)?.toInt(),
    ultimaMedida: j['ultimaMedida'] == null ? null : _medidaDataString(j['ultimaMedida']),
    cicloMedidasDias: (j['cicloMedidasDias'] as num?)?.toInt() ?? 30,
  );
}

/// Gordura por avaliação: medida não tem esse campo.
typedef PontoGordura = ({String data, double valor});

/// BFF `GET /api/alunos/{id}/evolucao/home`: tudo que a tela precisa.
class EvolucaoHomeBundle {
  final List<MedidaCorporal> medidas;
  final List<RecordePessoal> recordes;
  final List<MetaCorporal> metas;
  final List<PontoGordura> gordura;
  final EvolucaoAneis aneis;

  const EvolucaoHomeBundle({
    required this.medidas,
    required this.recordes,
    this.metas = const [],
    this.gordura = const [],
    this.aneis = const EvolucaoAneis(),
  });

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
      metas: [
        for (final item in (j['metas'] as List?) ?? const [])
          MetaCorporal.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      gordura: [
        for (final item in (j['gordura'] as List?) ?? const [])
          (
            data: _medidaDataString((item as Map)['data']),
            valor: (item['valor'] as num).toDouble(),
          ),
      ],
      aneis:
          j['aneis'] is Map
              ? EvolucaoAneis.fromJson(Map<String, dynamic>.from(j['aneis'] as Map))
              : const EvolucaoAneis(),
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

  /// Evolução do próprio aluno: medidas e recordes.
  Future<EvolucaoHomeBundle> minhaEvolucao() async {
    final r = await _dio.get('/api/aluno/evolucao');
    return EvolucaoHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }

  Map<String, dynamic> _corpoDaMedida(
    MedidaCorporal medida, {
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
  }) => {
    'data': medida.data,
    'peso': peso,
    'cintura': cintura,
    'quadril': quadril,
    'braco': braco,
  };

  Future<void> editarMedida(
    int alunoId,
    MedidaCorporal medida, {
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
  }) => _dio.put(
    '/api/alunos/$alunoId/medidas/${medida.id}',
    data: _corpoDaMedida(
      medida,
      peso: peso,
      cintura: cintura,
      quadril: quadril,
      braco: braco,
    ),
  );

  Future<void> editarMinhaMedida(
    MedidaCorporal medida, {
    double? peso,
    double? cintura,
    double? quadril,
    double? braco,
  }) => _dio.put(
    '/api/aluno/medidas/${medida.id}',
    data: _corpoDaMedida(
      medida,
      peso: peso,
      cintura: cintura,
      quadril: quadril,
      braco: braco,
    ),
  );

  Map<String, dynamic> _corpoDaMeta({
    required String metrica,
    double? alvo,
    DateTime? prazo,
    String? observacao,
    bool manter = false,
  }) => {
    'metrica': metrica,
    'valorAlvo': alvo,
    'prazo': prazo?.toIso8601String().substring(0, 10),
    'observacao': observacao,
    'manter': manter,
  };

  Future<void> criarMeta(
    int alunoId, {
    required String metrica,
    required double alvo,
    DateTime? prazo,
    String? observacao,
  }) => _dio.post(
    '/api/alunos/$alunoId/metas',
    data: _corpoDaMeta(
      metrica: metrica,
      alvo: alvo,
      prazo: prazo,
      observacao: observacao,
    ),
  );

  Future<void> manterResultado(int alunoId, String metrica) => _dio.post(
    '/api/alunos/$alunoId/metas',
    data: _corpoDaMeta(metrica: metrica, manter: true),
  );

  Future<void> editarMeta(
    int alunoId,
    MetaCorporal meta, {
    required double alvo,
    DateTime? prazo,
    String? observacao,
  }) => _dio.put(
    '/api/alunos/$alunoId/metas/${meta.id}',
    data: _corpoDaMeta(
      metrica: meta.metrica,
      alvo: alvo,
      prazo: prazo,
      observacao: observacao,
    ),
  );

  /// `confirmar`, `devolver`, `encerrar` ou `sem-proximo-passo`.
  Future<void> acaoDeMeta(int alunoId, int metaId, String acao) =>
      _dio.post('/api/alunos/$alunoId/metas/$metaId/$acao');

  Future<void> excluirMedida(int alunoId, int medidaId) =>
      _dio.delete('/api/alunos/$alunoId/medidas/$medidaId');

  Future<void> excluirMinhaMedida(int medidaId) =>
      _dio.delete('/api/aluno/medidas/$medidaId');

  Future<void> excluirFoto(int alunoId, int fotoId) =>
      _dio.delete('/api/alunos/$alunoId/fotos/$fotoId');

  Future<void> excluirMinhaFoto(int fotoId) =>
      _dio.delete('/api/aluno/fotos/$fotoId');

  Future<Pagina<FotoEvolucao>> minhasFotos({int page = 0}) async {
    final r = await _dio.get(
      '/api/aluno/fotos',
      queryParameters: {'page': page, 'size': 30},
    );
    return Pagina.fromJson(
      Map<String, dynamic>.from(r.data as Map),
      (item) => FotoEvolucao.fromJson(Map<String, dynamic>.from(item as Map)),
    );
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

  Map<String, dynamic> _corpoDoRecorde({
    int? exercicioId,
    required String exercicioNome,
    required String data,
    required double carga,
    int? repeticoes,
  }) => {
    if (exercicioId != null) 'exercicioId': exercicioId,
    'exercicioNome': exercicioNome,
    'data': data,
    'cargaKg': carga,
    if (repeticoes != null) 'repeticoes': repeticoes,
  };

  Future<void> editarRecorde(
    int alunoId,
    RecordePessoal recorde, {
    int? exercicioId,
    required String exercicioNome,
    required double carga,
    int? repeticoes,
  }) => _dio.put(
    '/api/alunos/$alunoId/recordes/${recorde.id}',
    data: _corpoDoRecorde(
      exercicioId: exercicioId,
      exercicioNome: exercicioNome,
      data: recorde.data,
      carga: carga,
      repeticoes: repeticoes,
    ),
  );

  Future<void> excluirRecorde(int alunoId, int recordeId) =>
      _dio.delete('/api/alunos/$alunoId/recordes/$recordeId');

  Future<void> definirCicloMedidas(int alunoId, int dias) => _dio.put(
    '/api/alunos/$alunoId/ciclo-medidas',
    data: {'dias': dias},
  );

  Future<RecordePessoal> adicionarRecorde(
    int alunoId, {
    int? exercicioId,
    required String exercicioNome,
    required double carga,
    int? repeticoes,
  }) async {
    final r = await _dio.post(
      '/api/alunos/$alunoId/recordes',
      data: _corpoDoRecorde(
        exercicioId: exercicioId,
        exercicioNome: exercicioNome,
        data: DateTime.now().toIso8601String().substring(0, 10),
        carga: carga,
        repeticoes: repeticoes,
      ),
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

  Future<({List<EventoEngajamento> eventos, AderenciaResumo? aderencia})>
  engajamento(int alunoId, {int dias = 30}) async {
    final r = await _dio.get(
      '/api/alunos/$alunoId/engajamento',
      queryParameters: {'dias': dias, 'limit': 200},
    );
    final data = r.data;
    final eventos = data is Map ? (data['eventos'] as List?) ?? [] : data as List;
    final aderencia = data is Map ? data['aderencia'] : null;
    return (
      eventos:
          eventos
              .map((e) => EventoEngajamento.fromJson(e as Map<String, dynamic>))
              .toList(),
      aderencia:
          aderencia is Map
              ? AderenciaResumo.fromJson(Map<String, dynamic>.from(aderencia))
              : null,
    );
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
  final String? registradoPor;

  const FotoEvolucao({
    required this.id,
    required this.url,
    required this.data,
    this.registradoPor,
  });

  factory FotoEvolucao.fromJson(Map<String, dynamic> j) => FotoEvolucao(
    id: (j['id'] as num?)?.toInt() ?? 0,
    url: j['url'] as String? ?? j['fotoUrl'] as String? ?? '',
    data: j['data'] as String? ?? j['createdAt'] as String? ?? '',
    registradoPor: j['registradoPor'] as String?,
  );
}
