import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/health/health_service.dart';

/// Após tentativa de sync: só snapshot do servidor; falha mantém o anterior.
RecoverySnapshot? recoveryAfterSyncAttempt({
  required RecoverySnapshot? syncedFromServer,
  required RecoverySnapshot? previousSnapshot,
}) {
  return syncedFromServer ?? previousSnapshot;
}

class RecoverySnapshot {
  final DateTime? dataReferencia;
  final int steps;
  final double caloriesBurned;
  final double avgHeartRate;
  final double sleepHours;

  /// Índice 0–100 calculado no servidor; null = indisponível (nunca 0).
  final int? recoveryScore;
  final String recoveryLabel;
  final String recoveryHint;
  final DateTime? sincronizadoEm;

  /// FC em repouso e HRV do dia; zero = não medido.
  final double restingHeartRate;
  final double hrv;

  /// Sono presente e base ainda curta: sem nota, "calibrando".
  final bool calibrando;

  /// Dados que entraram na nota: `sono`, `fcRepouso`, `hrv`.
  final List<String> insumos;

  const RecoverySnapshot({
    this.dataReferencia,
    required this.steps,
    required this.caloriesBurned,
    required this.avgHeartRate,
    required this.sleepHours,
    required this.recoveryScore,
    required this.recoveryLabel,
    required this.recoveryHint,
    this.sincronizadoEm,
    this.restingHeartRate = 0,
    this.hrv = 0,
    this.calibrando = false,
    this.insumos = const [],
  });

  factory RecoverySnapshot.fromJson(
    Map<String, dynamic> json,
  ) => RecoverySnapshot(
    dataReferencia: DateTime.tryParse(json['dataReferencia'] as String? ?? ''),
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0,
    avgHeartRate: (json['avgHeartRate'] as num?)?.toDouble() ?? 0,
    sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
    recoveryScore: (json['recoveryScore'] as num?)?.toInt(),
    recoveryLabel: json['recoveryLabel'] as String? ?? '',
    recoveryHint: json['recoveryHint'] as String? ?? '',
    sincronizadoEm: DateTime.tryParse(json['sincronizadoEm'] as String? ?? ''),
    restingHeartRate: (json['restingHeartRate'] as num?)?.toDouble() ?? 0,
    hrv: (json['hrv'] as num?)?.toDouble() ?? 0,
    calibrando: json['calibrando'] as bool? ?? false,
    insumos: [
      for (final i in (json['insumos'] as List<dynamic>? ?? const []))
        i.toString(),
    ],
  );
}

class HealthRepository {
  HealthRepository(this._dio);

  final Dio _dio;

  factory HealthRepository.fromClient(ApiClient client) =>
      HealthRepository(client.dio);

  Future<RecoverySnapshot?> fetchRecoveryForAluno(int alunoId) async {
    try {
      final response = await _dio.get(
        '/api/personal/alunos/$alunoId/saude/recovery',
      );
      if (response.statusCode == 204 || response.data == null) return null;
      return RecoverySnapshot.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 204) return null;
      rethrow;
    }
  }

  Future<RecoverySnapshot> syncToday(HealthSummary summary) async {
    final response = await _dio.post(
      '/api/aluno/saude/sync',
      data: {
        'steps': summary.steps,
        'caloriesBurned': summary.caloriesBurned,
        'avgHeartRate': summary.avgHeartRate,
        'sleepHours': summary.sleepHours,
        'restingHeartRate': summary.restingHeartRate,
        'hrv': summary.hrv,
      },
    );
    return RecoverySnapshot.fromJson(response.data as Map<String, dynamic>);
  }

  /// Últimos [dias] dias de prontidão (máximo 30), do mais antigo ao mais novo.
  Future<List<RecoveryDia>> historicoDeProntidao({int dias = 7}) async {
    final response = await _dio.get(
      '/api/aluno/saude/historico',
      queryParameters: {'dias': dias},
    );
    final lista = response.data as List<dynamic>? ?? const [];
    return [
      for (final item in lista)
        RecoveryDia.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<bool> compartilhamento() async {
    final response = await _dio.get('/api/aluno/saude/compartilhamento');
    return (response.data as Map<String, dynamic>)['ativo'] as bool? ?? false;
  }

  Future<bool> definirCompartilhamento(bool ativo) async {
    final response = await _dio.put(
      '/api/aluno/saude/compartilhamento',
      data: {'ativo': ativo},
    );
    return (response.data as Map<String, dynamic>)['ativo'] as bool? ?? ativo;
  }
}

/// Um dia do histórico de prontidão.
class RecoveryDia {
  const RecoveryDia({
    required this.data,
    required this.score,
    required this.rotulo,
    required this.sonoHoras,
    required this.fcRepouso,
    required this.passos,
  });

  final DateTime data;
  final int? score;
  final String? rotulo;
  final double sonoHoras;
  final double fcRepouso;
  final int passos;

  factory RecoveryDia.fromJson(Map<String, dynamic> json) => RecoveryDia(
    data: DateTime.tryParse(json['data'] as String? ?? '') ?? DateTime.now(),
    score: (json['score'] as num?)?.toInt(),
    rotulo: json['rotulo'] as String?,
    sonoHoras: (json['sonoHoras'] as num?)?.toDouble() ?? 0,
    fcRepouso: (json['fcRepouso'] as num?)?.toDouble() ?? 0,
    passos: (json['passos'] as num?)?.toInt() ?? 0,
  );
}
