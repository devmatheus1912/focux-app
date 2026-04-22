import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import 'command_center_data.dart';

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

  Future<DashboardData> getDashboard() async {
    final response = await _dio.get('/api/dashboard/personal');
    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CommandCenterData> getCommandCenter() async {
    final response = await _dio.get('/api/dashboard/command-center');
    return CommandCenterData.fromJson(response.data as Map<String, dynamic>);
  }
}
