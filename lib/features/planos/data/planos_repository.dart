import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class TrialStatus {
  final bool trialUsed;
  final DateTime? trialEndsAt;
  final int diasRestantes;
  final String planoAtual;

  TrialStatus({required this.trialUsed, this.trialEndsAt, required this.diasRestantes, required this.planoAtual});

  factory TrialStatus.fromJson(Map<String, dynamic> j) => TrialStatus(
    trialUsed: j['trialUsed'] as bool? ?? false,
    trialEndsAt: j['trialEndsAt'] != null ? DateTime.tryParse(j['trialEndsAt'].toString()) : null,
    diasRestantes: (j['diasRestantes'] as num?)?.toInt() ?? 0,
    planoAtual: j['planoAtual'] as String? ?? 'FREE',
  );
}

class PlanosRepository {
  final Dio _dio;
  PlanosRepository(ApiClient client) : _dio = client.dio;

  Future<TrialStatus> getTrialStatus() async {
    final r = await _dio.get('/api/personal/trial/status');
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
  }

  Future<TrialStatus> startTrial({String? iapToken}) async {
    final r = await _dio.post('/api/personal/trial/start',
      queryParameters: iapToken != null ? {'iapToken': iapToken} : null);
    return TrialStatus.fromJson(r.data as Map<String, dynamic>);
  }
}
