import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../alertas/data/alertas_repository.dart';
import '../../exercicios/data/enums.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../health/data/health_repository.dart';

class Aluno {
  final int id;
  final String nome;
  final String email;
  final String? objetivo;
  final String status;
  final String? fotoUrl;
  final bool inadimplente;
  final bool emRisco;
  final String? telefone;
  final String? whatsapp;
  final String? genero;
  final String? tipoConsultoria;
  final String statusFinanceiro;
  final int? scoreProntidao;
  final String? senhaProvisoria;
  final double? peso;
  final double? altura;
  final String? dataNascimento;
  final Set<Equipamento> equipamentosDisponiveis;
  final int? aderenciaPercent;
  final int? diasSemTreino;
  final String? riscoNivel;
  final String? proximoContato;
  final String? snoozedUntil;
  final String? ultimoContato;
  final bool? operacaoFocusMode;

  Aluno({
    required this.id,
    required this.nome,
    required this.email,
    this.objetivo,
    required this.status,
    this.fotoUrl,
    this.inadimplente = false,
    this.emRisco = false,
    this.telefone,
    this.whatsapp,
    this.genero,
    this.tipoConsultoria,
    this.statusFinanceiro = 'ATIVO',
    this.scoreProntidao,
    this.senhaProvisoria,
    this.peso,
    this.altura,
    this.dataNascimento,
    this.equipamentosDisponiveis = const {},
    this.aderenciaPercent,
    this.diasSemTreino,
    this.riscoNivel,
    this.proximoContato,
    this.snoozedUntil,
    this.ultimoContato,
    this.operacaoFocusMode,
  });

  DateTime? get followUpDate {
    final raw = proximoContato?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? get snoozedUntilDate => DateTime.tryParse(snoozedUntil ?? '');

  DateTime? get ultimoContatoDate {
    final raw = ultimoContato?.trim();
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  int? get idade {
    if (dataNascimento == null) return null;
    final nasc = DateTime.tryParse(dataNascimento!);
    if (nasc == null) return null;
    final now = DateTime.now();
    int age = now.year - nasc.year;
    if (now.month < nasc.month ||
        (now.month == nasc.month && now.day < nasc.day)) {
      age--;
    }
    return age;
  }

  factory Aluno.fromJson(Map<String, dynamic> json) => Aluno(
    id: json['id'] as int,
    nome: json['nome'] as String,
    email: json['email'] as String? ?? '',
    objetivo: json['objetivo'] as String?,
    status: json['status'] as String,
    fotoUrl: json['fotoUrl'] as String?,
    inadimplente: json['inadimplente'] as bool? ?? false,
    emRisco: json['emRisco'] as bool? ?? false,
    telefone: json['telefone'] as String?,
    whatsapp: json['whatsapp'] as String?,
    genero: json['genero'] as String?,
    tipoConsultoria: json['tipoConsultoria'] as String?,
    statusFinanceiro: json['statusFinanceiro'] as String? ?? 'ATIVO',
    scoreProntidao: json['scoreProntidao'] as int?,
    senhaProvisoria: json['senhaProvisoria'] as String?,
    peso: json['peso']?.toDouble(),
    altura: json['altura']?.toDouble(),
    dataNascimento: json['dataNascimento'] as String?,
    aderenciaPercent: (json['aderenciaPercent'] as num?)?.toInt(),
    diasSemTreino: (json['diasSemTreino'] as num?)?.toInt(),
    riscoNivel: json['riscoNivel'] as String?,
    proximoContato: json['proximoContato'] as String?,
    snoozedUntil: json['snoozedUntil'] as String?,
    ultimoContato: json['ultimoContato'] as String?,
    operacaoFocusMode: json['operacaoFocusMode'] as bool?,
    equipamentosDisponiveis:
        parseEnumCsv(
          Equipamento.values,
          json['equipamentosDisponiveis'] ??
              json['equipamentosDisponiveisCsv'] ??
              json['equipamentos_disponiveis'],
        ).toSet(),
  );
}

class AlunosStats {
  final int total;
  final int totalAtivos;
  final int totalInadimplentes;
  final int totalRiscoAlto;
  final int totalConvites;

  const AlunosStats({
    required this.total,
    required this.totalAtivos,
    required this.totalInadimplentes,
    required this.totalRiscoAlto,
    required this.totalConvites,
  });

  factory AlunosStats.fromJson(Map<String, dynamic> json) => AlunosStats(
    total: (json['total'] as num?)?.toInt() ?? 0,
    totalAtivos: (json['totalAtivos'] as num?)?.toInt() ?? 0,
    totalInadimplentes: (json['totalInadimplentes'] as num?)?.toInt() ?? 0,
    totalRiscoAlto: (json['totalRiscoAlto'] as num?)?.toInt() ?? 0,
    totalConvites: (json['totalConvites'] as num?)?.toInt() ?? 0,
  );
}

class AlunoAutonomiaEvento {
  final int id;
  final String taskId;
  final String taskTitle;
  final String action;
  final String? route;
  final String? priority;
  final bool done;
  final int? profileCompletion;
  final DateTime? criadoEm;

  const AlunoAutonomiaEvento({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.action,
    this.route,
    this.priority,
    this.done = false,
    this.profileCompletion,
    this.criadoEm,
  });

  factory AlunoAutonomiaEvento.fromJson(Map<String, dynamic> json) =>
      AlunoAutonomiaEvento(
        id: (json['id'] as num).toInt(),
        taskId: json['taskId'] as String? ?? '',
        taskTitle: json['taskTitle'] as String? ?? 'Tarefa do aluno',
        action: json['action'] as String? ?? '',
        route: json['route'] as String?,
        priority: json['priority'] as String?,
        done: json['done'] as bool? ?? false,
        profileCompletion: (json['profileCompletion'] as num?)?.toInt(),
        criadoEm:
            json['criadoEm'] == null
                ? null
                : DateTime.tryParse(json['criadoEm'].toString()),
      );
}

/// Sinais de evolução a partir de check-ins concluídos (backend).
class EvolucaoInteligente {
  final String sinal;
  final String resumo;
  final String? ultimoPrLabel;
  final double? ultimoPrCargaKg;
  final String? ultimoPrExercicio;
  final double volumeSemanal;
  final double volumeMensal;
  final int? tendenciaVolumePct;
  final String proximaAcao;
  final bool sugerirCopiloto;
  final List<double> volumePorSemana;

  const EvolucaoInteligente({
    required this.sinal,
    required this.resumo,
    this.ultimoPrLabel,
    this.ultimoPrCargaKg,
    this.ultimoPrExercicio,
    required this.volumeSemanal,
    required this.volumeMensal,
    this.tendenciaVolumePct,
    required this.proximaAcao,
    required this.sugerirCopiloto,
    this.volumePorSemana = const [],
  });

  factory EvolucaoInteligente.fromJson(Map<String, dynamic> json) =>
      EvolucaoInteligente(
        sinal: json['sinal'] as String? ?? 'SEM_DADOS',
        resumo: json['resumo'] as String? ?? '',
        ultimoPrLabel: json['ultimoPrLabel'] as String?,
        ultimoPrCargaKg: (json['ultimoPrCargaKg'] as num?)?.toDouble(),
        ultimoPrExercicio: json['ultimoPrExercicio'] as String?,
        volumeSemanal: (json['volumeSemanal'] as num?)?.toDouble() ?? 0,
        volumeMensal: (json['volumeMensal'] as num?)?.toDouble() ?? 0,
        tendenciaVolumePct: (json['tendenciaVolumePct'] as num?)?.toInt(),
        proximaAcao: json['proximaAcao'] as String? ?? '',
        sugerirCopiloto: json['sugerirCopiloto'] as bool? ?? false,
        volumePorSemana:
            (json['volumePorSemana'] as List<dynamic>?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            const [],
      );
}

class Timeline360Event {
  final String tipo;
  final String titulo;
  final String corpo;
  final String meta;
  final String ocorridoEm;
  final String deepLink;
  final String prioridade;

  const Timeline360Event({
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.meta,
    required this.ocorridoEm,
    required this.deepLink,
    required this.prioridade,
  });

  factory Timeline360Event.fromJson(Map<String, dynamic> json) =>
      Timeline360Event(
        tipo: json['tipo'] as String? ?? '',
        titulo: json['titulo'] as String? ?? '',
        corpo: json['corpo'] as String? ?? '',
        meta: json['meta'] as String? ?? '',
        ocorridoEm: json['ocorridoEm'] as String? ?? '',
        deepLink: json['deepLink'] as String? ?? '',
        prioridade: json['prioridade'] as String? ?? 'P2',
      );
}

class ProximaAcaoResumo {
  final String acao;
  final String motivo;
  final String fonte;
  final String prioridade;
  final String? fonteLabel;
  final String? tipoAcao;
  final String? mensagemSugerida;
  final String? stickyLabel;
  final String? stickyLabelCompact;
  final String? ctaLabel;
  final bool? wearableRelevant;

  const ProximaAcaoResumo({
    required this.acao,
    required this.motivo,
    required this.fonte,
    required this.prioridade,
    this.fonteLabel,
    this.tipoAcao,
    this.mensagemSugerida,
    this.stickyLabel,
    this.stickyLabelCompact,
    this.ctaLabel,
    this.wearableRelevant,
  });

  factory ProximaAcaoResumo.fromJson(Map<String, dynamic> json) =>
      ProximaAcaoResumo(
        acao: json['acao'] as String? ?? '',
        motivo: json['motivo'] as String? ?? '',
        fonte: json['fonte'] as String? ?? 'PADRAO',
        prioridade: json['prioridade'] as String? ?? 'P2',
        fonteLabel: json['fonteLabel'] as String?,
        tipoAcao: json['tipoAcao'] as String?,
        mensagemSugerida: json['mensagemSugerida'] as String?,
        stickyLabel: json['stickyLabel'] as String?,
        stickyLabelCompact: json['stickyLabelCompact'] as String?,
        ctaLabel: json['ctaLabel'] as String?,
        wearableRelevant: json['wearableRelevant'] as bool?,
      );
}

class AderenciaSemanalBundle {
  final List<Map<String, dynamic>> dias;
  final int totalSemana;
  final int streakAtual;
  final int diasComCheckin;
  final String resumo;

  const AderenciaSemanalBundle({
    this.dias = const [],
    this.totalSemana = 0,
    this.streakAtual = 0,
    this.diasComCheckin = 0,
    this.resumo = '',
  });

  factory AderenciaSemanalBundle.fromJson(Map<String, dynamic> json) =>
      AderenciaSemanalBundle(
        dias:
            (json['dias'] as List<dynamic>? ?? const [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
        totalSemana: (json['totalSemana'] as num?)?.toInt() ?? 0,
        streakAtual: (json['streakAtual'] as num?)?.toInt() ?? 0,
        diasComCheckin: (json['diasComCheckin'] as num?)?.toInt() ?? 0,
        resumo: json['resumo'] as String? ?? '',
      );

  factory AderenciaSemanalBundle.fromLegacyList(List<dynamic> raw) =>
      AderenciaSemanalBundle(
        dias: raw.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );

  static AderenciaSemanalBundle parse(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return AderenciaSemanalBundle.fromJson(raw);
    }
    if (raw is List) {
      return AderenciaSemanalBundle.fromLegacyList(raw);
    }
    return const AderenciaSemanalBundle();
  }
}

class RiscoResumo {
  const RiscoResumo({
    required this.score,
    required this.motivos,
    required this.nivel,
    required this.emRisco,
  });

  final int score;
  final List<String> motivos;
  final String nivel;
  final bool emRisco;

  factory RiscoResumo.fromJson(Map<String, dynamic> json) => RiscoResumo(
    score: (json['score'] as num?)?.toInt() ?? 0,
    motivos:
        (json['motivos'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
    nivel: (json['nivel'] as String?) ?? 'BAIXO',
    emRisco:
        json['emRisco'] as bool? ?? ((json['score'] as num?)?.toInt() ?? 0) > 0,
  );
}

class Timeline360Page {
  const Timeline360Page({
    required this.events,
    required this.hasMore,
    this.nextOffset,
    this.totalCount = 0,
  });

  final List<Timeline360Event> events;
  final bool hasMore;
  final int? nextOffset;
  final int totalCount;

  factory Timeline360Page.fromJson(Map<String, dynamic> json) =>
      Timeline360Page(
        events:
            (json['events'] as List<dynamic>? ?? const [])
                .map(
                  (e) => Timeline360Event.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
        hasMore: json['hasMore'] as bool? ?? false,
        nextOffset: (json['nextOffset'] as num?)?.toInt(),
        totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      );
}

class Aluno360 {
  final Aluno aluno;
  final AlunoAutonomiaResumo autonomiaResumo;
  final List<Timeline360Event> timelinePreview;
  final ProximaAcaoResumo proximaAcao;
  final EvolucaoInteligente evolucaoInteligente;
  final bool? hasOpenCopilotTask;
  final AderenciaSemanalBundle aderenciaSemanal;
  final bool? hasWearableHistory;
  final RecoverySnapshot? recoverySnapshot;
  final RiscoResumo? riscoResumo;

  const Aluno360({
    required this.aluno,
    required this.autonomiaResumo,
    required this.timelinePreview,
    required this.proximaAcao,
    required this.evolucaoInteligente,
    this.hasOpenCopilotTask,
    this.aderenciaSemanal = const AderenciaSemanalBundle(),
    this.hasWearableHistory,
    this.recoverySnapshot,
    this.riscoResumo,
  });

  factory Aluno360.fromJson(Map<String, dynamic> json) => Aluno360(
    aluno: Aluno.fromJson(json['aluno'] as Map<String, dynamic>),
    autonomiaResumo: AlunoAutonomiaResumo.fromJson(
      json['autonomiaResumo'] as Map<String, dynamic>,
    ),
    timelinePreview:
        (json['timelinePreview'] as List<dynamic>? ?? const [])
            .map((e) => Timeline360Event.fromJson(e as Map<String, dynamic>))
            .toList(),
    proximaAcao: ProximaAcaoResumo.fromJson(
      json['proximaAcao'] as Map<String, dynamic>,
    ),
    evolucaoInteligente: EvolucaoInteligente.fromJson(
      json['evolucaoInteligente'] as Map<String, dynamic>,
    ),
    hasOpenCopilotTask: json['hasOpenCopilotTask'] as bool?,
    aderenciaSemanal: AderenciaSemanalBundle.parse(json['aderenciaSemanal']),
    hasWearableHistory: json['hasWearableHistory'] as bool?,
    recoverySnapshot:
        json['recoverySnapshot'] != null
            ? RecoverySnapshot.fromJson(
              json['recoverySnapshot'] as Map<String, dynamic>,
            )
            : null,
    riscoResumo:
        json['riscoResumo'] != null
            ? RiscoResumo.fromJson(json['riscoResumo'] as Map<String, dynamic>)
            : null,
  );
}

class AlunoAutonomiaResumo {
  final int alunoId;
  final int totalEventos;
  final int vistos;
  final int cliques;
  final int concluidos;
  final String? gargaloTaskId;
  final String? gargaloTitulo;
  final String? gargaloPrioridade;
  final String? gargaloUltimaAcao;
  final DateTime? gargaloCriadoEm;

  const AlunoAutonomiaResumo({
    required this.alunoId,
    required this.totalEventos,
    required this.vistos,
    required this.cliques,
    required this.concluidos,
    this.gargaloTaskId,
    this.gargaloTitulo,
    this.gargaloPrioridade,
    this.gargaloUltimaAcao,
    this.gargaloCriadoEm,
  });

  factory AlunoAutonomiaResumo.fromJson(Map<String, dynamic> json) =>
      AlunoAutonomiaResumo(
        alunoId: (json['alunoId'] as num?)?.toInt() ?? 0,
        totalEventos: (json['totalEventos'] as num?)?.toInt() ?? 0,
        vistos: (json['vistos'] as num?)?.toInt() ?? 0,
        cliques: (json['cliques'] as num?)?.toInt() ?? 0,
        concluidos: (json['concluidos'] as num?)?.toInt() ?? 0,
        gargaloTaskId: json['gargaloTaskId'] as String?,
        gargaloTitulo: json['gargaloTitulo'] as String?,
        gargaloPrioridade: json['gargaloPrioridade'] as String?,
        gargaloUltimaAcao: json['gargaloUltimaAcao'] as String?,
        gargaloCriadoEm:
            json['gargaloCriadoEm'] == null
                ? null
                : DateTime.tryParse(json['gargaloCriadoEm'].toString()),
      );
}

class AlunoRepository {
  final Dio _dio;

  AlunoRepository(ApiClient client) : _dio = client.dio;

  Future<List<Aluno>> listar() async {
    final response = await _dio.get('/api/alunos');
    final list = response.data as List<dynamic>;
    return list.map((e) => Aluno.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// BFF tipado — first paint da lista (alunos + stats + alertas config).
  Future<AlunosHomeBundle> getHome() async {
    final response = await _dio.get('/api/alunos/home');
    return AlunosHomeBundle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlunosStats> buscarStats() async {
    final response = await _dio.get('/api/alunos/stats');
    return AlunosStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> atualizarFollowUp(
    int id, {
    String? proximoContato,
    String? snoozedUntil,
    bool clearSnooze = false,
    bool clearFollowUp = false,
  }) async {
    final response = await _dio.patch(
      '/api/alunos/$id/follow-up',
      data: {
        if (proximoContato != null) 'proximoContato': proximoContato,
        if (snoozedUntil != null) 'snoozedUntil': snoozedUntil,
        if (clearSnooze) 'clearSnooze': true,
        if (clearFollowUp) 'clearFollowUp': true,
      },
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> marcarContatoRealizado(int id) async {
    final response = await _dio.post('/api/alunos/$id/contato-realizado');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> atualizarOperacaoFocus(
    int id, {
    required bool focusMode,
  }) async {
    final response = await _dio.patch(
      '/api/alunos/$id/operacao-focus',
      data: {'focusMode': focusMode},
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> atualizarStatusLote(List<int> ids, String status) async {
    await _dio.patch(
      '/api/alunos/lote/status',
      data: {'alunoIds': ids, 'status': status},
    );
  }

  Future<Aluno> buscar(int id) async {
    final response = await _dio.get('/api/alunos/$id');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno360> buscarAluno360(int id) async {
    final response = await _dio.get('/api/alunos/$id/360');
    return Aluno360.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Aluno> criar({
    required String nome,
    required String email,
    String? objetivo,
    String? whatsapp,
    String? genero,
    String? tipoConsultoria,
  }) async {
    final response = await _dio.post(
      '/api/alunos',
      data: {
        'nome': nome,
        'email': email,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (whatsapp != null && whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (genero != null && genero.isNotEmpty) 'genero': genero,
        if (tipoConsultoria != null && tipoConsultoria.isNotEmpty)
          'tipoConsultoria': tipoConsultoria,
      },
    );
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> atualizarStatusFinanceiro(int alunoId, String status) async {
    await _dio.patch(
      '/api/alunos/$alunoId/status-financeiro',
      data: {'status': status},
    );
  }

  Future<Aluno> atualizarAluno(int id, Map<String, dynamic> data) async {
    final r = await _dio.put('/api/alunos/$id', data: data);
    return Aluno.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> excluirAluno(int id) async {
    await _dio.delete('/api/alunos/$id');
  }

  Future<void> atualizarEquipamentos(
    int alunoId,
    Set<Equipamento> equipamentos,
  ) async {
    await _dio.patch(
      '/api/alunos/$alunoId/equipamentos',
      data: {'equipamentos': equipamentos.map((e) => e.backendName).toList()},
    );
  }

  Future<List<Map<String, dynamic>>> aderenciaSemanal(int id) async {
    final response = await _dio.get('/api/alunos/$id/aderencia-semanal');
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return AderenciaSemanalBundle.fromJson(
      Map<String, dynamic>.from(data as Map),
    ).dias;
  }

  Future<AderenciaSemanalBundle> aderenciaSemanalBundle(int id) async {
    final response = await _dio.get('/api/alunos/$id/aderencia-semanal');
    final data = response.data;
    if (data is List) {
      return AderenciaSemanalBundle.fromLegacyList(data);
    }
    return AderenciaSemanalBundle.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }

  Future<List<AlunoAutonomiaEvento>> listarAutonomiaEventos(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/autonomia/eventos');
    return (response.data as List<dynamic>)
        .map((e) => AlunoAutonomiaEvento.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AlunoAutonomiaResumo> buscarAutonomiaResumo(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/autonomia/resumo');
    return AlunoAutonomiaResumo.fromJson(response.data as Map<String, dynamic>);
  }

  Future<EvolucaoInteligente> buscarEvolucaoInteligente(int alunoId) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/evolucao-inteligente',
    );
    return EvolucaoInteligente.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Timeline360Event>> buscarTimeline360(
    int alunoId, {
    int limit = 40,
  }) async {
    final page = await buscarTimeline360Page(alunoId, limit: limit);
    return page.events;
  }

  Future<Timeline360Page> buscarTimeline360Page(
    int alunoId, {
    int limit = 40,
    int offset = 0,
  }) async {
    final response = await _dio.get(
      '/api/alunos/$alunoId/timeline-360/page',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return Timeline360Page.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> gerarSenhaProvisoria(int id) async {
    final response = await _dio.post('/api/alunos/$id/gerar-senha-provisoria');
    return response.data['senhaProvisoria'] as String;
  }

  Future<Aluno> me() async {
    final response = await _dio.get('/api/aluno/me');
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  /// BFF tipado — first paint da aba Perfil (aluno + medidas).
  Future<AlunoPerfilHomeBundle> getPerfilHome() async {
    final response = await _dio.get('/api/aluno/perfil/home');
    return AlunoPerfilHomeBundle.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<Aluno> atualizarMe(Map<String, dynamic> data) async {
    final response = await _dio.put('/api/aluno/me', data: data);
    return Aluno.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> registrarEventoAutonomia({
    required String taskId,
    required String taskTitle,
    required String action,
    String? route,
    String? priority,
    bool? done,
    int? profileCompletion,
  }) async {
    await _dio.post(
      '/api/aluno/autonomia/eventos',
      data: {
        'taskId': taskId,
        'taskTitle': taskTitle,
        'action': action,
        if (route != null) 'route': route,
        if (priority != null) 'priority': priority,
        if (done != null) 'done': done,
        if (profileCompletion != null) 'profileCompletion': profileCompletion,
      },
    );
  }
}

class AlunosHomeBundle {
  static const fallbackDiasSemTreino = 7;
  static const fallbackAderenciaMinima = 50;

  final List<Aluno> alunos;
  final AlunosStats stats;
  final AlertasConfiguracao alertasConfig;

  const AlunosHomeBundle({
    required this.alunos,
    required this.stats,
    required this.alertasConfig,
  });

  factory AlunosHomeBundle.fromJson(Map<String, dynamic> j) => AlunosHomeBundle(
    alunos:
        ((j['alunos'] as List?) ?? const [])
            .map((e) => Aluno.fromJson(e as Map<String, dynamic>))
            .toList(),
    stats: AlunosStats.fromJson(
      (j['stats'] as Map<String, dynamic>?) ?? const {},
    ),
    alertasConfig: AlertasConfiguracao.fromJson(
      (j['alertasConfig'] as Map<String, dynamic>?) ??
          const {
            'diasSemTreino': fallbackDiasSemTreino,
            'aderenciaMinima': fallbackAderenciaMinima,
          },
    ),
  );
}

/// BFF `GET /api/aluno/perfil/home` — perfil + medidas em um round-trip.
class AlunoPerfilHomeBundle {
  final Aluno aluno;
  final List<MedidaCorporal> medidas;
  final DateTime fetchedAt;

  AlunoPerfilHomeBundle({
    required this.aluno,
    required this.medidas,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory AlunoPerfilHomeBundle.fromJson(Map<String, dynamic> json) {
    final alunoJson = json['aluno'];
    if (alunoJson is! Map<String, dynamic>) {
      throw const FormatException('aluno ausente em /api/aluno/perfil/home');
    }
    return AlunoPerfilHomeBundle(
      aluno: Aluno.fromJson(alunoJson),
      medidas:
          ((json['medidas'] as List?) ?? const [])
              .whereType<Map>()
              .map(
                (row) => MedidaCorporal.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
    );
  }
}
