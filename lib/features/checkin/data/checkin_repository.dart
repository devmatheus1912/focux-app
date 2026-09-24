import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';
import '../models/checkin_personal_home.dart';
import '../utils/checkin_json.dart';

class ExecucaoExercicio {
  final int id;
  final int treinoExercicioId;
  final String exercicioNome;
  final String? gifUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? videoSource;
  final String? licenseStatus;
  final String? errosComuns;
  final String? contraindicacoes;
  final String? substitutos;
  final int? series;
  final String? repeticoes;
  final double? cargaKg;
  final int? descansoSegundos;
  final String? observacoes;
  final int seriesFeitas;
  final bool concluido;
  final String? feedback;
  final int? rpe;
  final int? rpeAlvo;
  final bool dor;
  final double? cargaAnteriorKg;
  final int? seriesFeitasAnterior;
  final String? feedbackAnterior;
  final int? rpeAnterior;
  final bool? dorAnterior;
  final List<ExecucaoSerie> seriesDetalhes;
  final List<ExecucaoSerie> seriesAnteriores;

  ExecucaoExercicio({
    required this.id,
    required this.treinoExercicioId,
    required this.exercicioNome,
    this.gifUrl,
    this.thumbnailUrl,
    this.videoUrl,
    this.videoSource,
    this.licenseStatus,
    this.errosComuns,
    this.contraindicacoes,
    this.substitutos,
    this.series,
    this.repeticoes,
    this.cargaKg,
    this.descansoSegundos,
    this.observacoes,
    required this.seriesFeitas,
    required this.concluido,
    this.feedback,
    this.rpe,
    this.rpeAlvo,
    this.dor = false,
    this.cargaAnteriorKg,
    this.seriesFeitasAnterior,
    this.feedbackAnterior,
    this.rpeAnterior,
    this.dorAnterior,
    this.seriesDetalhes = const [],
    this.seriesAnteriores = const [],
  });

  factory ExecucaoExercicio.fromJson(Map<String, dynamic> j) =>
      ExecucaoExercicio(
        id: checkinJsonIntOr(j['id']),
        treinoExercicioId: checkinJsonIntOr(j['treinoExercicioId']),
        exercicioNome: checkinJsonStringOr(j['exercicioNome'], 'Exercício'),
        gifUrl: checkinJsonString(j['gifUrl']),
        thumbnailUrl: checkinJsonString(j['thumbnailUrl']),
        videoUrl: checkinJsonString(j['videoUrl']),
        videoSource: checkinJsonString(j['videoSource']),
        licenseStatus: checkinJsonString(j['licenseStatus']),
        errosComuns: checkinJsonString(j['errosComuns']),
        contraindicacoes: checkinJsonString(j['contraindicacoes']),
        substitutos: checkinJsonString(j['substitutos']),
        series: checkinJsonInt(j['series']),
        repeticoes: checkinJsonString(j['repeticoes']),
        cargaKg: checkinJsonDouble(j['cargaKg']),
        descansoSegundos: checkinJsonInt(j['descansoSegundos']),
        observacoes: checkinJsonString(j['observacoes']),
        seriesFeitas: checkinJsonIntOr(j['seriesFeitas']),
        concluido: checkinJsonBool(j['concluido']),
        feedback: checkinJsonString(j['feedback']),
        rpe: checkinJsonInt(j['rpe']),
        rpeAlvo: checkinJsonInt(j['rpeAlvo']),
        dor: checkinJsonBool(j['dor']),
        cargaAnteriorKg: checkinJsonDouble(j['cargaAnteriorKg']),
        seriesFeitasAnterior: checkinJsonInt(j['seriesFeitasAnterior']),
        feedbackAnterior: checkinJsonString(j['feedbackAnterior']),
        rpeAnterior: checkinJsonInt(j['rpeAnterior']),
        dorAnterior:
            j['dorAnterior'] == null ? null : checkinJsonBool(j['dorAnterior']),
        seriesDetalhes:
            checkinJsonMapList(
              j['seriesDetalhes'],
            ).map(ExecucaoSerie.fromJson).toList(),
        seriesAnteriores:
            checkinJsonMapList(
              j['seriesAnteriores'],
            ).map(ExecucaoSerie.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'treinoExercicioId': treinoExercicioId,
    'exercicioNome': exercicioNome,
    'gifUrl': gifUrl,
    'thumbnailUrl': thumbnailUrl,
    'videoUrl': videoUrl,
    'videoSource': videoSource,
    'licenseStatus': licenseStatus,
    'errosComuns': errosComuns,
    'contraindicacoes': contraindicacoes,
    'substitutos': substitutos,
    'series': series,
    'repeticoes': repeticoes,
    'cargaKg': cargaKg,
    'descansoSegundos': descansoSegundos,
    'observacoes': observacoes,
    'seriesFeitas': seriesFeitas,
    'concluido': concluido,
    'feedback': feedback,
    'rpe': rpe,
    'rpeAlvo': rpeAlvo,
    'dor': dor,
    'cargaAnteriorKg': cargaAnteriorKg,
    'seriesFeitasAnterior': seriesFeitasAnterior,
    'feedbackAnterior': feedbackAnterior,
    'rpeAnterior': rpeAnterior,
    'dorAnterior': dorAnterior,
    'seriesDetalhes': seriesDetalhes.map((s) => s.toJson()).toList(),
    'seriesAnteriores': seriesAnteriores.map((s) => s.toJson()).toList(),
  };

  ExecucaoExercicio copyWith({
    int? seriesFeitas,
    bool? concluido,
    String? feedback,
    int? rpe,
    bool? dor,
  }) => ExecucaoExercicio(
    id: id,
    treinoExercicioId: treinoExercicioId,
    exercicioNome: exercicioNome,
    gifUrl: gifUrl,
    thumbnailUrl: thumbnailUrl,
    videoUrl: videoUrl,
    videoSource: videoSource,
    licenseStatus: licenseStatus,
    errosComuns: errosComuns,
    contraindicacoes: contraindicacoes,
    substitutos: substitutos,
    series: series,
    repeticoes: repeticoes,
    cargaKg: cargaKg,
    descansoSegundos: descansoSegundos,
    observacoes: observacoes,
    seriesFeitas: seriesFeitas ?? this.seriesFeitas,
    concluido: concluido ?? this.concluido,
    feedback: feedback ?? this.feedback,
    rpe: rpe ?? this.rpe,
    rpeAlvo: rpeAlvo,
    dor: dor ?? this.dor,
    cargaAnteriorKg: cargaAnteriorKg,
    seriesFeitasAnterior: seriesFeitasAnterior,
    feedbackAnterior: feedbackAnterior,
    rpeAnterior: rpeAnterior,
    dorAnterior: dorAnterior,
    seriesDetalhes: seriesDetalhes,
    seriesAnteriores: seriesAnteriores,
  );
}

class ExecucaoSerie {
  final int id;
  final int numero;
  final double? cargaKg;
  final String? repeticoes;
  final String? feedback;
  final int? rpe;
  final bool dor;
  final String? criadoEm;

  const ExecucaoSerie({
    required this.id,
    required this.numero,
    this.cargaKg,
    this.repeticoes,
    this.feedback,
    this.rpe,
    this.dor = false,
    this.criadoEm,
  });

  factory ExecucaoSerie.fromJson(Map<String, dynamic> json) => ExecucaoSerie(
    id: checkinJsonIntOr(json['id']),
    numero: checkinJsonIntOr(json['numero']),
    cargaKg: checkinJsonDouble(json['cargaKg']),
    repeticoes: checkinJsonString(json['repeticoes']),
    feedback: checkinJsonString(json['feedback']),
    rpe: checkinJsonInt(json['rpe']),
    dor: checkinJsonBool(json['dor']),
    criadoEm: checkinJsonString(json['criadoEm']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'cargaKg': cargaKg,
    'repeticoes': repeticoes,
    'feedback': feedback,
    'rpe': rpe,
    'dor': dor,
    'criadoEm': criadoEm,
  };
}

class ExecucaoTreino {
  final int? id;
  final int treinoId;
  final String treinoNome;
  final String status;
  final String? iniciadoEm;
  final String? concluidoEm;
  /// Vigência da atribuição (meus-treinos); ISO date.
  final String? dataInicio;
  /// Prazo soft — orientação; nunca bloqueia check-in.
  final String? dataFim;
  final List<ExecucaoExercicio> exercicios;
  final List<EvolucaoCarga> evolucoesCarga;
  final List<EvolucaoPerformance> evolucoesPerformance;

  ExecucaoTreino({
    this.id,
    required this.treinoId,
    required this.treinoNome,
    required this.status,
    this.iniciadoEm,
    this.concluidoEm,
    this.dataInicio,
    this.dataFim,
    required this.exercicios,
    this.evolucoesCarga = const [],
    this.evolucoesPerformance = const [],
  });

  factory ExecucaoTreino.fromJson(Map<String, dynamic> j) => ExecucaoTreino(
    id: checkinJsonInt(j['id']),
    treinoId: checkinJsonIntOr(j['treinoId']),
    treinoNome: checkinJsonStringOr(j['treinoNome'], 'Treino'),
    status: checkinJsonStringOr(j['status'], 'PENDENTE'),
    iniciadoEm: checkinJsonString(j['iniciadoEm']),
    concluidoEm: checkinJsonString(j['concluidoEm']),
    dataInicio: checkinJsonString(j['dataInicio']),
    dataFim: checkinJsonString(j['dataFim']),
    exercicios:
        checkinJsonMapList(
          j['exercicios'],
        ).map(ExecucaoExercicio.fromJson).toList(),
    evolucoesCarga:
        checkinJsonMapList(
          j['evolucoesCarga'],
        ).map(EvolucaoCarga.fromJson).toList(),
    evolucoesPerformance:
        checkinJsonMapList(
          j['evolucoesPerformance'],
        ).map(EvolucaoPerformance.fromJson).toList(),
  );

  /// Item slim do BFF `historicoResumo` (sem séries/mídia/evoluções).
  factory ExecucaoTreino.fromHistoricoResumoJson(Map<String, dynamic> j) {
    return ExecucaoTreino(
      id: checkinJsonInt(j['id']),
      treinoId: checkinJsonIntOr(j['treinoId']),
      treinoNome: checkinJsonStringOr(j['treinoNome'], 'Treino'),
      status: checkinJsonStringOr(j['status'], 'PENDENTE'),
      iniciadoEm: checkinJsonString(j['iniciadoEm']),
      concluidoEm: checkinJsonString(j['concluidoEm']),
      exercicios: const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'treinoId': treinoId,
    'treinoNome': treinoNome,
    'status': status,
    'iniciadoEm': iniciadoEm,
    'concluidoEm': concluidoEm,
    'dataInicio': dataInicio,
    'dataFim': dataFim,
    'exercicios': exercicios.map((e) => e.toJson()).toList(),
    'evolucoesCarga': [],
    'evolucoesPerformance': [],
  };
}

class EvolucaoCarga {
  final int exercicioId;
  final String exercicioNome;
  final double cargaAnteriorKg;
  final double cargaAtualKg;
  final double diferencaKg;
  final int? percentual;
  final String mensagem;

  const EvolucaoCarga({
    required this.exercicioId,
    required this.exercicioNome,
    required this.cargaAnteriorKg,
    required this.cargaAtualKg,
    required this.diferencaKg,
    this.percentual,
    required this.mensagem,
  });

  factory EvolucaoCarga.fromJson(Map<String, dynamic> json) => EvolucaoCarga(
    exercicioId: checkinJsonIntOr(json['exercicioId']),
    exercicioNome: checkinJsonStringOr(json['exercicioNome'], 'Exercício'),
    cargaAnteriorKg: checkinJsonDouble(json['cargaAnteriorKg']) ?? 0,
    cargaAtualKg: checkinJsonDouble(json['cargaAtualKg']) ?? 0,
    diferencaKg: checkinJsonDouble(json['diferencaKg']) ?? 0,
    percentual: checkinJsonInt(json['percentual']),
    mensagem: checkinJsonStringOr(json['mensagem']),
  );
}

class EvolucaoPerformance {
  final String tipo;
  final int exercicioId;
  final String exercicioNome;
  final double valorAnterior;
  final double valorAtual;
  final double diferenca;
  final int? percentual;
  final String unidade;
  final String mensagem;

  const EvolucaoPerformance({
    required this.tipo,
    required this.exercicioId,
    required this.exercicioNome,
    required this.valorAnterior,
    required this.valorAtual,
    required this.diferenca,
    this.percentual,
    required this.unidade,
    required this.mensagem,
  });

  factory EvolucaoPerformance.fromJson(Map<String, dynamic> json) =>
      EvolucaoPerformance(
        tipo: checkinJsonStringOr(json['tipo'], 'CARGA'),
        exercicioId: checkinJsonIntOr(json['exercicioId']),
        exercicioNome: checkinJsonStringOr(json['exercicioNome'], 'Exercício'),
        valorAnterior: checkinJsonDouble(json['valorAnterior']) ?? 0,
        valorAtual: checkinJsonDouble(json['valorAtual']) ?? 0,
        diferenca: checkinJsonDouble(json['diferenca']) ?? 0,
        percentual: checkinJsonInt(json['percentual']),
        unidade: checkinJsonStringOr(json['unidade']),
        mensagem: checkinJsonStringOr(json['mensagem']),
      );
}

/// Resumo BFF da sessão (`GET /checkin/{id}/evolucao-sessao`).
class SessaoEvolucaoDto {
  final int? execucaoId;
  final double? volumeKg;
  final double? volumeAnteriorKg;
  final int seriesFeitas;
  final int seriesPlanejadas;
  final int recordes;
  final String sinal;
  final String sinalLabel;
  final String? destaqueExercicio;
  final double? destaqueDeltaKg;

  const SessaoEvolucaoDto({
    this.execucaoId,
    this.volumeKg,
    this.volumeAnteriorKg,
    required this.seriesFeitas,
    required this.seriesPlanejadas,
    required this.recordes,
    required this.sinal,
    required this.sinalLabel,
    this.destaqueExercicio,
    this.destaqueDeltaKg,
  });

  factory SessaoEvolucaoDto.fromJson(Map<String, dynamic> j) => SessaoEvolucaoDto(
    execucaoId: checkinJsonInt(j['execucaoId']),
    volumeKg: checkinJsonDouble(j['volumeKg']),
    volumeAnteriorKg: checkinJsonDouble(j['volumeAnteriorKg']),
    seriesFeitas: checkinJsonIntOr(j['seriesFeitas']),
    seriesPlanejadas: checkinJsonIntOr(j['seriesPlanejadas']),
    recordes: checkinJsonIntOr(j['recordes']),
    sinal: checkinJsonStringOr(j['sinal'], 'SEM_DADOS'),
    sinalLabel: checkinJsonStringOr(
      j['sinalLabel'],
      'Sem séries registradas',
    ),
    destaqueExercicio: checkinJsonString(j['destaqueExercicio']),
    destaqueDeltaKg: checkinJsonDouble(j['destaqueDeltaKg']),
  );
}

Pagina<ExecucaoTreino> parseExecucaoTreinoPagina(Map<String, dynamic> json) {
  final raw = json['content'];
  if (raw is! List) {
    throw FormatException(
      'Pagina exige content (array). Chaves recebidas: ${json.keys.join(', ')}',
    );
  }
  final content = <ExecucaoTreino>[];
  for (final item in raw) {
    final map = checkinJsonMap(item);
    if (map == null) continue;
    try {
      content.add(ExecucaoTreino.fromJson(map));
    } catch (_) {
      // Linha corrompida não derruba a lista inteira.
    }
  }
  return Pagina<ExecucaoTreino>(
    content: content,
    hasNext: json['hasNext'] == true,
    page: checkinJsonInt(json['page']),
    size: checkinJsonInt(json['size']),
    totalElements: checkinJsonInt(json['totalElements']),
    nextCursor: checkinJsonString(json['nextCursor']),
  );
}

Map<String, dynamic> _requireJsonMap(dynamic data, String endpoint) =>
    checkinRequireEntityJson(data, endpoint);

class CheckinRepository {
  final Dio _dio;

  CheckinRepository(ApiClient client) : _dio = client.dio;

  Future<Pagina<ExecucaoTreino>> meusTreinosPagina({
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      '/api/checkin/meus-treinos',
      queryParameters: {'page': page, 'size': size},
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/checkin/meus-treinos devolve Pagina, não lista crua.',
      );
    }
    return parseExecucaoTreinoPagina(Map<String, dynamic>.from(data));
  }

  Future<List<ExecucaoTreino>> meusTreinos({
    int page = 0,
    int size = 20,
  }) async {
    return (await meusTreinosPagina(page: page, size: size)).content;
  }

  Future<ExecucaoTreino> iniciar(int treinoId) async {
    final r = await _dio.post(
      '/api/checkin/iniciar',
      data: {'treinoId': treinoId},
    );
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'POST /api/checkin/iniciar'),
    );
  }

  Future<ExecucaoExercicio> marcarExercicio(
    int execucaoId,
    int treinoExercicioId,
    int seriesFeitas, {
    String? feedback,
    int? rpe,
    bool? dor,
  }) async {
    final r = await _dio.put(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId',
      data: {
        'seriesFeitas': seriesFeitas,
        if (feedback != null) 'feedback': feedback,
        if (rpe != null) 'rpe': rpe,
        if (dor != null) 'dor': dor,
      },
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'PUT /api/checkin/{id}/exercicio/{treinoExercicioId}',
      ),
    );
  }

  Future<ExecucaoExercicio> registrarSerie(
    int execucaoId,
    int treinoExercicioId, {
    required int numero,
    double? cargaKg,
    String? repeticoes,
    String? feedback,
    int? rpe,
    bool? dor,
    int? presencialAlunoId,
  }) async {
    final path =
        presencialAlunoId != null
            ? '/api/checkin/personal/$execucaoId/exercicio/$treinoExercicioId/series'
            : '/api/checkin/$execucaoId/exercicio/$treinoExercicioId/series';
    final r = await _dio.post(
      path,
      data: {
        'numero': numero,
        if (cargaKg != null) 'cargaKg': cargaKg,
        if (repeticoes != null && repeticoes.isNotEmpty)
          'repeticoes': repeticoes,
        if (feedback != null) 'feedback': feedback,
        if (rpe != null) 'rpe': rpe,
        if (dor != null) 'dor': dor,
      },
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'POST checkin serie',
      ),
    );
  }

  Future<ExecucaoExercicio> confirmarRestante(
    int execucaoId,
    int treinoExercicioId,
  ) async {
    final r = await _dio.post(
      '/api/checkin/$execucaoId/exercicio/$treinoExercicioId/confirmar-restante',
    );
    return ExecucaoExercicio.fromJson(
      _requireJsonMap(
        r.data,
        'POST /api/checkin/{id}/exercicio/{treinoExercicioId}/confirmar-restante',
      ),
    );
  }

  Future<ExecucaoTreino> confirmarPlano(int treinoId) async {
    final r = await _dio.post(
      '/api/checkin/confirmar-plano',
      data: {'treinoId': treinoId},
    );
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'POST /api/checkin/confirmar-plano'),
    );
  }

  Future<ExecucaoTreino> descartar(int execucaoId) async {
    final r = await _dio.put('/api/checkin/$execucaoId/descartar');
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT /api/checkin/{id}/descartar'),
    );
  }

  Future<ExecucaoTreino> concluir(
    int execucaoId, {
    int? presencialAlunoId,
  }) async {
    final path =
        presencialAlunoId != null
            ? '/api/checkin/personal/$execucaoId/concluir'
            : '/api/checkin/$execucaoId/concluir';
    final r = await _dio.put(path);
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'PUT checkin concluir'),
    );
  }

  Future<ExecucaoTreino> detalhe(int execucaoId) async {
    final r = await _dio.get('/api/checkin/$execucaoId');
    return ExecucaoTreino.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/{id}'),
    );
  }

  Future<SessaoEvolucaoDto> evolucaoSessao(int execucaoId) async {
    final r = await _dio.get('/api/checkin/$execucaoId/evolucao-sessao');
    return SessaoEvolucaoDto.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/{id}/evolucao-sessao'),
    );
  }

  Future<Pagina<ExecucaoTreino>> historico({
    String? cursor,
    int size = 20,
    String? q,
    String? status,
  }) async {
    final query = q?.trim() ?? '';
    final statusFilter = status?.trim() ?? '';
    final r = await _dio.get(
      '/api/checkin/historico',
      queryParameters: {
        'size': size,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (query.isNotEmpty) 'q': query,
        if (statusFilter.isNotEmpty) 'status': statusFilter,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/checkin/historico devolve Pagina, não lista crua.',
      );
    }
    return parseExecucaoTreinoPagina(Map<String, dynamic>.from(data));
  }

  static const personalHomePageSize = 20;

  Future<CheckinPersonalHomeBundle> personalHome({
    int page = 0,
    String? q,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/checkin/personal/home',
      queryParameters: {
        'page': page,
        'size': personalHomePageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return CheckinPersonalHomeBundle.fromJson(
      _requireJsonMap(r.data, 'GET /api/checkin/personal/home'),
    );
  }
}
