import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../financeiro/data/financeiro_repository.dart';
import 'command_center_data.dart';

class DashboardHomeBundle {
  final DashboardData personal;
  final CommandCenterData commandCenter;
  final FinanceiroDashboard financeiro;

  DashboardHomeBundle({
    required this.personal,
    required this.commandCenter,
    required this.financeiro,
  });

  factory DashboardHomeBundle.fromJson(Map<String, dynamic> json) =>
      DashboardHomeBundle(
        personal: DashboardData.fromJson(
          json['personal'] as Map<String, dynamic>,
        ),
        commandCenter: CommandCenterData.fromJson(
          json['commandCenter'] as Map<String, dynamic>,
        ),
        financeiro: FinanceiroDashboard.fromJson(
          json['financeiro'] as Map<String, dynamic>,
        ),
      );
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
