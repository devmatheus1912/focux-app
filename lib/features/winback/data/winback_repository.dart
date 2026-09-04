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

class WinbackLogPage {
  const WinbackLogPage({
    required this.itens,
    this.page = 0,
    this.totalItens = 0,
    this.hasNext = false,
  });

  final List<WinbackLogEntry> itens;
  final int page;
  final int totalItens;
  final bool hasNext;

  factory WinbackLogPage.fromJson(dynamic raw) {
    if (raw is List) {
      final itens =
          raw
              .whereType<Map>()
              .map(
                (row) =>
                    WinbackLogEntry.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList();
      return WinbackLogPage(itens: itens, totalItens: itens.length);
    }
    final json = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    final list = json['content'] ?? json['itens'];
    final itens =
        list is List
            ? list
                .whereType<Map>()
                .map(
                  (row) =>
                      WinbackLogEntry.fromJson(Map<String, dynamic>.from(row)),
                )
                .toList()
            : const <WinbackLogEntry>[];
    return WinbackLogPage(
      itens: itens,
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalItens:
          (json['totalElements'] as num?)?.toInt() ??
          (json['totalItens'] as num?)?.toInt() ??
          itens.length,
      hasNext: json['hasNext'] == true,
    );
  }
}

class WinbackRepository {
  final Dio _dio;

  WinbackRepository(ApiClient client) : _dio = client.dio;

  static const pageSize = 20;

  Future<WinbackLogPage> log({int page = 0, String q = ''}) async {
    final query = q.trim();
    final response = await _dio.get(
      '/api/winback/log',
      queryParameters: {
        'page': page,
        'size': pageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return WinbackLogPage.fromJson(response.data);
  }
}
