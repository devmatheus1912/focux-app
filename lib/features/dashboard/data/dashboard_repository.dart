import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_etag_store.dart';
import '../../../core/providers/personal_brand_provider.dart';
import '../../alunos/data/aluno_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../checkin/data/checkin_repository.dart';
import '../../coach/data/coach_proativo_repository.dart';
import '../../evolucao/data/evolucao_repository.dart';
import '../../financeiro/data/financeiro_repository.dart';
import '../../health/data/health_repository.dart';
import '../../monetizacao/data/upsell_repository.dart';
import '../../onboarding/data/onboarding_status_data.dart';
import '../../planos/data/planos_repository.dart';
import '../utils/aluno_dashboard_home_client_cache.dart';
import '../utils/aluno_performance_evolution.dart';
import '../utils/dashboard_day_focus.dart';
import '../utils/dashboard_home_client_cache.dart';
import 'command_center_data.dart';

class DashboardAderenciaTopItem {
  final int alunoId;
  final String nome;
  final String? objetivo;
  final List<double> sparkline;
  final int totalCheckinsSemana;
  final int aderenciaPercent;

  const DashboardAderenciaTopItem({
    required this.alunoId,
    required this.nome,
    required this.objetivo,
    required this.sparkline,
    required this.totalCheckinsSemana,
    required this.aderenciaPercent,
  });

  factory DashboardAderenciaTopItem.fromJson(Map<String, dynamic> json) {
    final sparkRaw = json['sparkline'] as List<dynamic>? ?? const [];
    return DashboardAderenciaTopItem(
      alunoId: (json['alunoId'] as num).toInt(),
      nome: json['nome'] as String? ?? '',
      objetivo: json['objetivo'] as String?,
      sparkline:
          sparkRaw.map((e) => (e as num?)?.toDouble() ?? 0.0).toList(growable: false),
      totalCheckinsSemana: (json['totalCheckinsSemana'] as num?)?.toInt() ?? 0,
      aderenciaPercent: (json['aderenciaPercent'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Pulso operacional embutido no BFF `/home` (evita sidecars no first paint).
class DashboardPulseSnapshot {
  final int? checkinsHoje;
  final int? mensagensNaoLidas;
  final int? coachPendentes;
  final List<int> checkinsTrend;
  final String? emptyHint;

  const DashboardPulseSnapshot({
    this.checkinsHoje,
    this.mensagensNaoLidas,
    this.coachPendentes,
    this.checkinsTrend = const [],
    this.emptyHint,
  });

  factory DashboardPulseSnapshot.fromJson(Map<String, dynamic> json) {
    final trendRaw = json['checkinsTrend'] as List<dynamic>? ?? const [];
    return DashboardPulseSnapshot(
      checkinsHoje: (json['checkinsHoje'] as num?)?.toInt(),
      mensagensNaoLidas: (json['mensagensNaoLidas'] as num?)?.toInt(),
      coachPendentes: (json['coachPendentes'] as num?)?.toInt() ??
          (json['coachPending'] as num?)?.toInt(),
      checkinsTrend:
          trendRaw
              .map((e) => (e as num?)?.toInt() ?? 0)
              .toList(growable: false),
      emptyHint: json['emptyHint'] as String?,
    );
  }
}

class DashboardHomeBundle {
  final DashboardData personal;
  final CommandCenterData commandCenter;
  final FinanceiroDashboard financeiro;
  final List<DashboardAderenciaTopItem> topAderencia;
  final DashboardPulseSnapshot? pulse;
  final int? notificacoesNaoLidas;
  final OnboardingStatusData? onboardingResumo;
  final PlanoFeatures? planoFeatures;
  final DashboardDayFocus? dayFocus;

  DashboardHomeBundle({
    required this.personal,
    required this.commandCenter,
    required this.financeiro,
    this.topAderencia = const [],
    this.pulse,
    this.notificacoesNaoLidas,
    this.onboardingResumo,
    this.planoFeatures,
    this.dayFocus,
  });

  factory DashboardHomeBundle.fromJson(Map<String, dynamic> json) {
    final topRaw = json['topAderencia'] as List<dynamic>? ?? const [];
    final pulseRaw = json['pulse'];
    final onboardingRaw = json['onboardingResumo'];
    final planoRaw = json['planoFeatures'];
    final dayFocusRaw = json['dayFocus'];
    return DashboardHomeBundle(
      personal: DashboardData.fromJson(
        json['personal'] as Map<String, dynamic>,
      ),
      commandCenter: CommandCenterData.fromJson(
        json['commandCenter'] as Map<String, dynamic>,
      ),
      financeiro: FinanceiroDashboard.fromJson(
        json['financeiro'] as Map<String, dynamic>,
      ),
      topAderencia:
          topRaw
              .whereType<Map>()
              .map(
                (e) => DashboardAderenciaTopItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(growable: false),
      pulse:
          pulseRaw is Map
              ? DashboardPulseSnapshot.fromJson(
                Map<String, dynamic>.from(pulseRaw),
              )
              : null,
      notificacoesNaoLidas: (json['notificacoesNaoLidas'] as num?)?.toInt(),
      onboardingResumo:
          onboardingRaw is Map
              ? OnboardingStatusData.fromJson(
                Map<String, dynamic>.from(onboardingRaw),
              )
              : null,
      planoFeatures:
          planoRaw is Map
              ? PlanoFeatures.fromJson(Map<String, dynamic>.from(planoRaw))
              : null,
      dayFocus:
          dayFocusRaw is Map
              ? DashboardDayFocus.fromJson(
                Map<String, dynamic>.from(dayFocusRaw),
              )
              : null,
    );
  }
}

class DashboardData {
  final int totalAlunos;
  final int alunosAtivos;
  final String planoAtual;
  final int limiteAlunos;
  final String? nomePersonal;
  final String? logoUrl;
  final String? corPrimaria;
  final String? corSecundaria;
  final String? descricaoProfissional;
  final String? instagram;

  DashboardData({
    required this.totalAlunos,
    required this.alunosAtivos,
    required this.planoAtual,
    required this.limiteAlunos,
    this.nomePersonal,
    this.logoUrl,
    this.corPrimaria,
    this.corSecundaria,
    this.descricaoProfissional,
    this.instagram,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
    totalAlunos: json['totalAlunos'] as int,
    alunosAtivos: json['alunosAtivos'] as int,
    planoAtual: json['planoAtual'] as String,
    limiteAlunos: json['limiteAlunos'] as int,
    nomePersonal: json['nomePersonal'] as String?,
    logoUrl: json['logoUrl'] as String?,
    corPrimaria: json['corPrimaria'] as String?,
    corSecundaria: json['corSecundaria'] as String?,
    descricaoProfissional: json['descricaoProfissional'] as String?,
    instagram: json['instagram'] as String?,
  );
}

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(ApiClient client) : _dio = client.dio;

  /// `null` = HTTP 304 com body no ClientCache — caller reusa cache.
  /// 304 órfão (sem body): limpa ETag, retry 1× sem If-None-Match, devolve 200.
  Future<DashboardHomeBundle?> getHome() async {
    // Garante probe do ClientCache antes do interceptor decidir If-None-Match.
    DashboardHomeClientCache.hasBody;
    final response = await _dio.get(DashboardHomeClientCache.etagPath);
    if (response.statusCode != 304) {
      return _parsePersonalHome(response.data);
    }
    if (DashboardHomeClientCache.hasBody) return null;

    ApiEtagStore.removeForPath(
      method: 'GET',
      path: DashboardHomeClientCache.etagPath,
    );
    final retry = await _dio.get(
      DashboardHomeClientCache.etagPath,
      options: Options(extra: const {'fxSkipEtag': true}),
    );
    return _parsePersonalHome(retry.data);
  }

  DashboardHomeBundle _parsePersonalHome(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw StateError('GET /api/dashboard/home: body inválido');
    }
    return DashboardHomeBundle.fromJson(data);
  }

  static const iaCommandActionsPageSize = 20;

  Future<IaCommandActionsPage> getIaCommandActionsPage({
    String? status,
    int? alunoId,
    int page = 0,
    String? q,
  }) async {
    final query = q?.trim() ?? '';
    final response = await _dio.get(
      '/api/dashboard/command-center/actions/ia',
      queryParameters: {
        'page': page,
        'size': iaCommandActionsPageSize,
        if (status != null && status.isNotEmpty) 'status': status,
        if (alunoId != null) 'alunoId': alunoId,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return IaCommandActionsPage.fromJson(response.data);
  }

  Future<IaCommandActionsContagem> getIaCommandActionsContagem() async {
    final response = await _dio.get(
      '/api/dashboard/command-center/actions/ia/contagem',
    );
    return IaCommandActionsContagem.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<List<FilaAcaoResumo>> getIaCommandActions({
    String? status,
    int? alunoId,
  }) async {
    final page = await getIaCommandActionsPage(
      status: status,
      alunoId: alunoId,
    );
    return page.itens;
  }

  Future<void> completeCommandAction(String actionKey) async {
    await _dio.post(
      '/api/dashboard/command-center/actions/complete',
      data: {'actionKey': actionKey},
    );
  }

  Future<void> reopenCommandAction(String actionKey) async {
    await _dio.post(
      '/api/dashboard/command-center/actions/reopen',
      data: {'actionKey': actionKey},
    );
  }

  Future<void> snoozeCommandAction(String actionKey, {int hours = 24}) async {
    await _dio.post(
      '/api/dashboard/command-center/actions/snooze',
      data: {'actionKey': actionKey, 'hours': hours},
    );
  }

  /// `null` = HTTP 304 com body no ClientCache — caller reusa cache.
  /// 304 órfão (sem body): limpa ETag, retry 1× sem If-None-Match, devolve 200.
  Future<AlunoDashboardHomeBundle?> getAlunoHome() async {
    AlunoDashboardHomeClientCache.hasBody;
    final response = await _dio.get(AlunoDashboardHomeClientCache.etagPath);
    if (response.statusCode != 304) {
      return _parseAlunoHome(response.data);
    }
    if (AlunoDashboardHomeClientCache.hasBody) return null;

    ApiEtagStore.removeForPath(
      method: 'GET',
      path: AlunoDashboardHomeClientCache.etagPath,
    );
    final retry = await _dio.get(
      AlunoDashboardHomeClientCache.etagPath,
      options: Options(extra: const {'fxSkipEtag': true}),
    );
    return _parseAlunoHome(retry.data);
  }

  AlunoDashboardHomeBundle _parseAlunoHome(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw StateError('GET /api/dashboard/aluno/home: body inválido');
    }
    return AlunoDashboardHomeBundle.fromJson(data);
  }
}

/// Sinal de chat do BFF aluno (sem marcar mensagens como lidas).
class AlunoDashboardChatResumo {
  final bool possuiMensagemDoAluno;
  final DateTime? ultimaMensagemAlunoEm;
  final int naoLidasDoPersonal;

  const AlunoDashboardChatResumo({
    required this.possuiMensagemDoAluno,
    this.ultimaMensagemAlunoEm,
    required this.naoLidasDoPersonal,
  });

  factory AlunoDashboardChatResumo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AlunoDashboardChatResumo(
        possuiMensagemDoAluno: false,
        naoLidasDoPersonal: 0,
      );
    }
    return AlunoDashboardChatResumo(
      possuiMensagemDoAluno: json['possuiMensagemDoAluno'] as bool? ?? false,
      ultimaMensagemAlunoEm: DateTime.tryParse(
        json['ultimaMensagemAlunoEm']?.toString() ?? '',
      ),
      naoLidasDoPersonal: (json['naoLidasDoPersonal'] as num?)?.toInt() ?? 0,
    );
  }

  /// Compat com [buildAlunoHomeExperience] sem dump do histórico.
  List<ChatMsg> toSyntheticMessages() {
    if (!possuiMensagemDoAluno || ultimaMensagemAlunoEm == null) {
      return const [];
    }
    return [
      ChatMsg(
        remetente: 'ALUNO',
        conteudo: '',
        enviadoEm: ultimaMensagemAlunoEm!,
      ),
    ];
  }
}

/// BFF `GET /api/dashboard/aluno/home` — single round-trip da Home do aluno.
class AlunoDashboardHomeBundle {
  final Aluno aluno;
  final PersonalBrand personalBrand;
  final List<ExecucaoTreino> treinos;
  final List<ExecucaoTreino> historico;
  final List<MedidaCorporal> medidas;
  final AlunoDashboardChatResumo chat;
  final int notificacoesNaoLidas;
  final List<CoachMensagem> coachMensagens;
  final List<AlunoOferta> upsellPendentes;
  final bool npsDeveResponder;
  final RecoverySnapshot? recovery;
  final bool hasWearableHistory;
  final int streakAtual;
  final double volumeSemanaKg;
  final double volumeMesKg;
  final List<double> volumePorSemana;
  final List<double> forcaPorSemana;
  final List<RecordePessoal> recordes;
  /// Meta semanal (dias) da prescrição ativa — SSOT do BFF.
  final int? frequenciaDias;
  final DateTime fetchedAt;

  AlunoDashboardHomeBundle({
    required this.aluno,
    required this.personalBrand,
    required this.treinos,
    required this.historico,
    required this.medidas,
    required this.chat,
    required this.notificacoesNaoLidas,
    this.coachMensagens = const [],
    this.upsellPendentes = const [],
    this.npsDeveResponder = false,
    this.recovery,
    this.hasWearableHistory = false,
    this.streakAtual = 0,
    this.volumeSemanaKg = 0,
    this.volumeMesKg = 0,
    this.volumePorSemana = const [],
    this.forcaPorSemana = const [],
    this.recordes = const [],
    this.frequenciaDias,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory AlunoDashboardHomeBundle.fromJson(Map<String, dynamic> json) {
    List<ExecucaoTreino> parseExec(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => ExecucaoTreino.fromJson(e as Map<String, dynamic>))
            .toList();
    List<ExecucaoTreino> parseHistorico(Map<String, dynamic> json) {
      const historicoCap = 12;
      // BFF #75: se a chave `historicoResumo` veio (mesmo vazia), é a SSOT —
      // não parsear dump `historico` rico.
      if (json.containsKey('historicoResumo')) {
        final resumo = json['historicoResumo'];
        if (resumo is! List) return const [];
        final list = resumo
            .whereType<Map>()
            .map(
              (e) => ExecucaoTreino.fromHistoricoResumoJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList(growable: false);
        if (list.length <= historicoCap) return list;
        return list.sublist(0, historicoCap);
      }
      // API antiga: dump completo — slim + cap no client (Home não precisa séries).
      final full = parseExec(json['historico']);
      final slim = full
          .take(historicoCap)
          .map(
            (e) => ExecucaoTreino(
              id: e.id,
              treinoId: e.treinoId,
              treinoNome: e.treinoNome,
              status: e.status,
              iniciadoEm: e.iniciadoEm,
              concluidoEm: e.concluidoEm,
              exercicios: const [],
            ),
          )
          .toList(growable: false);
      return slim;
    }
    List<MedidaCorporal> parseMedidas(dynamic raw) {
      final list =
          (raw as List? ?? const [])
              .map((e) => MedidaCorporal.fromJson(e as Map<String, dynamic>))
              .toList();
      // Caps client se o BFF ainda mandar dump completo.
      if (list.length <= 5) return list;
      return list.sublist(0, 5);
    }
    List<CoachMensagem> parseCoach(dynamic raw) {
      final list =
          (raw as List? ?? const [])
              .map((e) => CoachMensagem.fromJson(e as Map<String, dynamic>))
              .toList();
      if (list.length <= 5) return list;
      return list.sublist(0, 5);
    }
    List<AlunoOferta> parseUpsell(dynamic raw) {
      final list =
          (raw as List? ?? const [])
              .map((e) => AlunoOferta.fromJson(e as Map<String, dynamic>))
              .toList();
      if (list.length <= 5) return list;
      return list.sublist(0, 5);
    }
    List<RecordePessoal> parseRecordes(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => RecordePessoal.fromJson(e as Map<String, dynamic>))
            .toList();
    final recoveryRaw = json['recovery'];
    final evolucaoHome = json['evolucaoHome'];
    final recordesRaw =
        json['recordes'] ??
        (evolucaoHome is Map ? evolucaoHome['recordes'] : null);

    return AlunoDashboardHomeBundle(
      aluno: Aluno.fromJson(
        Map<String, dynamic>.from(json['aluno'] as Map),
      ),
      personalBrand: PersonalBrand.fromJson(
        Map<String, dynamic>.from(
          (json['personalBrand'] as Map?) ?? const {},
        ),
      ),
      treinos: parseExec(json['treinos']),
      historico: parseHistorico(json),
      medidas: parseMedidas(json['medidas']),
      chat: AlunoDashboardChatResumo.fromJson(
        json['chat'] is Map
            ? Map<String, dynamic>.from(json['chat'] as Map)
            : null,
      ),
      notificacoesNaoLidas:
          (json['notificacoesNaoLidas'] as num?)?.toInt() ?? 0,
      coachMensagens: parseCoach(json['coachMensagens']),
      upsellPendentes: parseUpsell(json['upsellPendentes']),
      npsDeveResponder: json['npsDeveResponder'] as bool? ?? false,
      recovery:
          recoveryRaw is Map
              ? RecoverySnapshot.fromJson(
                Map<String, dynamic>.from(recoveryRaw),
              )
              : null,
      hasWearableHistory: json['hasWearableHistory'] as bool? ?? false,
      streakAtual: (json['streakAtual'] as num?)?.toInt() ?? 0,
      volumeSemanaKg: (json['volumeSemanaKg'] as num?)?.toDouble() ?? 0,
      volumeMesKg: (json['volumeMesKg'] as num?)?.toDouble() ?? 0,
      volumePorSemana: parseAlunoHomeSeries(json['volumePorSemana']),
      forcaPorSemana: parseAlunoHomeSeries(json['forcaPorSemana']),
      recordes: parseRecordes(recordesRaw),
      frequenciaDias: (json['frequenciaDias'] as num?)?.toInt(),
    );
  }
}
