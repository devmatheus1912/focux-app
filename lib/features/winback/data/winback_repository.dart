import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class WinbackLogEntry {
  final int? alunoId;
  final String alunoNome;
  final String tipo;
  final String mensagem;
  final String enviadoEm;

  const WinbackLogEntry({
    this.alunoId,
    required this.alunoNome,
    required this.tipo,
    required this.mensagem,
    required this.enviadoEm,
  });

  factory WinbackLogEntry.fromJson(Map<String, dynamic> json) =>
      WinbackLogEntry(
        alunoId: (json['alunoId'] as num?)?.toInt(),
        alunoNome: json['alunoNome'] as String? ?? 'Aluno',
        tipo: json['tipo'] as String? ?? '',
        mensagem: json['mensagem'] as String? ?? '',
        enviadoEm: json['enviadoEm']?.toString() ?? '',
      );
}

class WinbackRepository {
  final Dio _dio;

  WinbackRepository(ApiClient client) : _dio = client.dio;

  static const pageSize = 20;

  Future<List<WinbackLogEntry>> log({int page = 0, String q = ''}) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/winback/log',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return (response.data as List<dynamic>)
        .map((e) => WinbackLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
