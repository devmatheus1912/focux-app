import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
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
import '../utils/dashboard_day_focus.dart';
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
  final List<int> checkinsTrend;
  final String? emptyHint;

  const DashboardPulseSnapshot({
    this.checkinsHoje,
    this.mensagensNaoLidas,
    this.checkinsTrend = const [],
    this.emptyHint,
  });

  factory DashboardPulseSnapshot.fromJson(Map<String, dynamic> json) {
    final trendRaw = json['checkinsTrend'] as List<dynamic>? ?? const [];
    return DashboardPulseSnapshot(
      checkinsHoje: (json['checkinsHoje'] as num?)?.toInt(),
      mensagensNaoLidas: (json['mensagensNaoLidas'] as num?)?.toInt(),
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

  Future<DashboardHomeBundle> getHome() async {
    final response = await _dio.get('/api/dashboard/home');
    return DashboardHomeBundle.fromJson(response.data as Map<String, dynamic>);
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

  Future<AlunoDashboardHomeBundle> getAlunoHome() async {
    final response = await _dio.get('/api/dashboard/aluno/home');
    return AlunoDashboardHomeBundle.fromJson(
      response.data as Map<String, dynamic>,
    );
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
  final List<RecordePessoal> recordes;
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
    this.recordes = const [],
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory AlunoDashboardHomeBundle.fromJson(Map<String, dynamic> json) {
    List<ExecucaoTreino> parseExec(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => ExecucaoTreino.fromJson(e as Map<String, dynamic>))
            .toList();
    List<MedidaCorporal> parseMedidas(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => MedidaCorporal.fromJson(e as Map<String, dynamic>))
            .toList();
    List<CoachMensagem> parseCoach(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => CoachMensagem.fromJson(e as Map<String, dynamic>))
            .toList();
    List<AlunoOferta> parseUpsell(dynamic raw) =>
        (raw as List? ?? const [])
            .map((e) => AlunoOferta.fromJson(e as Map<String, dynamic>))
            .toList();
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
      aluno: Aluno.fromJson(json['aluno'] as Map<String, dynamic>),
      personalBrand: PersonalBrand.fromJson(
        json['personalBrand'] as Map<String, dynamic>? ?? const {},
      ),
      treinos: parseExec(json['treinos']),
      historico: parseExec(json['historico']),
      medidas: parseMedidas(json['medidas']),
      chat: AlunoDashboardChatResumo.fromJson(
        json['chat'] as Map<String, dynamic>?,
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
      recordes: parseRecordes(recordesRaw),
    );
  }
}
