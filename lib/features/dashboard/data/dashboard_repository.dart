import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../financeiro/data/financeiro_repository.dart';
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

  Future<List<FilaAcaoResumo>> getIaCommandActions({
    String? status,
    int? alunoId,
  }) async {
    final response = await _dio.get(
      '/api/dashboard/command-center/actions/ia',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (alunoId != null) 'alunoId': alunoId,
      },
    );
    return (response.data as List)
        .map((item) => FilaAcaoResumo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<FocuxScoreSnapshotResumo>> runFocuxScoreSnapshots() async {
    final response = await _dio.post(
      '/api/dashboard/focux-score/snapshots/run',
    );
    return (response.data as List)
        .map(
          (item) =>
              FocuxScoreSnapshotResumo.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<FocuxScoreSnapshotResumo>> getFocuxScoreSnapshots(
    int alunoId,
  ) async {
    final response = await _dio.get(
      '/api/dashboard/focux-score/snapshots',
      queryParameters: {'alunoId': alunoId},
    );
    return (response.data as List)
        .map(
          (item) =>
              FocuxScoreSnapshotResumo.fromJson(item as Map<String, dynamic>),
        )
        .toList();
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
}
