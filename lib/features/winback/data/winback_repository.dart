import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class WinbackLogEntry {
  final int id;
  final int? alunoId;
  final String alunoNome;
  final String tipo;
  final String mensagem;
  final String enviadoEm;

  const WinbackLogEntry({
    required this.id,
    this.alunoId,
    required this.alunoNome,
    required this.tipo,
    required this.mensagem,
    required this.enviadoEm,
  });

  factory WinbackLogEntry.fromJson(Map<String, dynamic> json) => WinbackLogEntry(
    id: (json['id'] as num).toInt(),
    alunoId: (json['alunoId'] as num?)?.toInt(),
    alunoNome: json['alunoNome'] as String? ?? 'Aluno',
    tipo: json['tipo'] as String? ?? '',
    mensagem: json['mensagem'] as String? ?? '',
    enviadoEm: json['enviadoEm'] as String? ?? '',
  );
}

class WinbackRepository {
  final Dio _dio;

  WinbackRepository(ApiClient client) : _dio = client.dio;

  Future<List<WinbackLogEntry>> log() async {
    final response = await _dio.get('/api/winback/log');
    return (response.data as List<dynamic>)
        .map((e) => WinbackLogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
