import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/health/health_service.dart';
import '../../../core/health/recovery_score.dart';

class RecoverySnapshot {
  final DateTime? dataReferencia;
  final int steps;
  final double caloriesBurned;
  final double avgHeartRate;
  final double sleepHours;
  final int recoveryScore;
  final String recoveryLabel;
  final String recoveryHint;
  final DateTime? sincronizadoEm;

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
  });

  factory RecoverySnapshot.fromJson(
    Map<String, dynamic> json,
  ) => RecoverySnapshot(
    dataReferencia: DateTime.tryParse(json['dataReferencia'] as String? ?? ''),
    steps: (json['steps'] as num?)?.toInt() ?? 0,
    caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0,
    avgHeartRate: (json['avgHeartRate'] as num?)?.toDouble() ?? 0,
    sleepHours: (json['sleepHours'] as num?)?.toDouble() ?? 0,
    recoveryScore: (json['recoveryScore'] as num?)?.toInt() ?? 0,
    recoveryLabel: json['recoveryLabel'] as String? ?? '',
    recoveryHint: json['recoveryHint'] as String? ?? '',
    sincronizadoEm: DateTime.tryParse(json['sincronizadoEm'] as String? ?? ''),
  );

  factory RecoverySnapshot.fromSummary(HealthSummary summary) {
    final recovery = RecoveryScoreView.compute(
      steps: summary.steps,
      sleepHours: summary.sleepHours,
      avgHeartRate: summary.avgHeartRate,
    );
    return RecoverySnapshot(
      steps: summary.steps,
      caloriesBurned: summary.caloriesBurned,
      avgHeartRate: summary.avgHeartRate,
      sleepHours: summary.sleepHours,
      recoveryScore: recovery.score,
      recoveryLabel: recovery.label,
      recoveryHint: recovery.hint,
      sincronizadoEm: DateTime.now(),
    );
  }
}

class HealthRepository {
  HealthRepository(this._dio);

  final Dio _dio;

  factory HealthRepository.fromClient(ApiClient client) =>
      HealthRepository(client.dio);

  Future<RecoverySnapshot?> fetchLatestRecovery() async {
    try {
      final response = await _dio.get('/api/aluno/saude/recovery');
      if (response.statusCode == 204 || response.data == null) return null;
      return RecoverySnapshot.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (error) {
      if (error.response?.statusCode == 204) return null;
      rethrow;
    }
  }

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
      },
    );
    return RecoverySnapshot.fromJson(response.data as Map<String, dynamic>);
  }
}
