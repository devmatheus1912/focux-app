import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class DashboardData {
  final int totalAlunos;
  final int alunosAtivos;
  final String planoAtual;
  final int limiteAlunos;

  DashboardData({
    required this.totalAlunos,
    required this.alunosAtivos,
    required this.planoAtual,
    required this.limiteAlunos,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalAlunos: json['totalAlunos'] as int,
        alunosAtivos: json['alunosAtivos'] as int,
        planoAtual: json['planoAtual'] as String,
        limiteAlunos: json['limiteAlunos'] as int,
      );
}

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(ApiClient client) : _dio = client.dio;

  Future<DashboardData> getDashboard() async {
    final response = await _dio.get('/api/dashboard/personal');
    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  }
}
