import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class WinbackLogEntry {
  final int? alunoId;
  final String alunoNome;
  final String tipo;
  final String mensagem;
  final String enviadoEm;
  final String? status;

  const WinbackLogEntry({
    this.alunoId,
    required this.alunoNome,
    required this.tipo,
    required this.mensagem,
    required this.enviadoEm,
    this.status,
  });

  factory WinbackLogEntry.fromJson(Map<String, dynamic> json) =>
      WinbackLogEntry(
        alunoId: (json['alunoId'] as num?)?.toInt(),
        alunoNome: json['alunoNome'] as String? ?? 'Aluno',
        tipo: json['tipo'] as String? ?? '',
        mensagem: json['mensagem'] as String? ?? '',
        enviadoEm: json['enviadoEm']?.toString() ?? '',
        status: json['status'] as String?,
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

  Future<RetomadaConfig> config() async {
    final r = await _dio.get('/api/winback/config');
    return RetomadaConfig.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// Texto vazio volta ao padrão do Focux.
  Future<RetomadaConfig> salvarConfig({
    required bool ativo,
    String? mensagem30,
    String? mensagem60,
  }) async {
    final r = await _dio.put(
      '/api/winback/config',
      data: {
        'ativo': ativo,
        'mensagem30': mensagem30,
        'mensagem60': mensagem60,
      },
    );
    return RetomadaConfig.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}

/// Aviso para quem parou: ligado e os textos (próprio ou o do Focux).
class RetomadaConfig {
  const RetomadaConfig({
    required this.ativo,
    required this.padrao30,
    required this.padrao60,
    this.mensagem30,
    this.mensagem60,
  });

  final bool ativo;
  final String? mensagem30;
  final String? mensagem60;
  final String padrao30;
  final String padrao60;

  bool get textoProprio => mensagem30 != null || mensagem60 != null;
  String get texto30 => mensagem30 ?? padrao30;
  String get texto60 => mensagem60 ?? padrao60;

  factory RetomadaConfig.fromJson(Map<String, dynamic> j) => RetomadaConfig(
    ativo: j['ativo'] as bool? ?? true,
    mensagem30: j['mensagem30'] as String?,
    mensagem60: j['mensagem60'] as String?,
    padrao30: j['padrao30'] as String? ?? '',
    padrao60: j['padrao60'] as String? ?? '',
  );
}
