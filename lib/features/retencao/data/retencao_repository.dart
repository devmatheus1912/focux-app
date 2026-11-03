import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class RetencaoAlunoScore {
  final int alunoId;
  final String alunoNome;
  final String nivel;
  final List<String> motivos;
  final int? diasSemTreino;
  final bool cobravel;
  final bool semFicha;
  final bool adiado;

  RetencaoAlunoScore({
    required this.alunoId,
    required this.alunoNome,
    required this.nivel,
    this.motivos = const [],
    this.diasSemTreino,
    this.cobravel = false,
    this.semFicha = false,
    this.adiado = false,
  });

  factory RetencaoAlunoScore.fromJson(Map<String, dynamic> j) =>
      RetencaoAlunoScore(
        alunoId: (j['alunoId'] as num).toInt(),
        alunoNome: (j['alunoNome'] as String?)?.trim() ?? '',
        nivel: j['nivel'] as String? ?? 'BAIXO',
        motivos: [
          for (final m in (j['motivos'] as List?) ?? const []) '$m',
        ],
        diasSemTreino: (j['diasSemTreino'] as num?)?.toInt(),
        cobravel: j['cobravel'] == true,
        semFicha: j['semFicha'] == true,
        adiado: j['adiado'] == true,
      );
}

class RetencaoHome {
  const RetencaoHome({
    required this.alto,
    required this.medio,
    required this.saudavel,
    required this.top3,
    this.altoSemanaAnterior,
    this.fetchedAt,
  });

  final int alto;
  final int medio;
  final int saudavel;
  final int? altoSemanaAnterior;
  final List<RetencaoAlunoScore> top3;
  final DateTime? fetchedAt;

  bool get isEmpty => alto == 0 && medio == 0 && saudavel == 0 && top3.isEmpty;

  factory RetencaoHome.fromJson(Map<String, dynamic> j) {
    return RetencaoHome(
      alto: (j['alto'] as num?)?.toInt() ?? 0,
      medio: (j['medio'] as num?)?.toInt() ?? 0,
      saudavel: (j['saudavel'] as num?)?.toInt() ?? 0,
      altoSemanaAnterior: (j['altoSemanaAnterior'] as num?)?.toInt(),
      top3:
          ((j['top3'] as List?) ?? const [])
              .whereType<Map>()
              .map(
                (e) => RetencaoAlunoScore.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
      fetchedAt: DateTime.tryParse(j['fetchedAt']?.toString() ?? ''),
    );
  }
}

class RetencaoBasePage {
  const RetencaoBasePage({
    required this.itens,
    this.page = 0,
    this.totalItens = 0,
    this.hasNext = false,
  });

  final List<RetencaoAlunoScore> itens;
  final int page;
  final int totalItens;
  final bool hasNext;

  factory RetencaoBasePage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'] ?? json['itens'];
    final itens =
        raw is List
            ? raw
                .whereType<Map>()
                .map(
                  (row) => RetencaoAlunoScore.fromJson(
                    Map<String, dynamic>.from(row),
                  ),
                )
                .toList()
            : const <RetencaoAlunoScore>[];
    return RetencaoBasePage(
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

class RetencaoRepository {
  final Dio _dio;
  RetencaoRepository(ApiClient c) : _dio = c.dio;

  static const basePageSize = 20;

  Future<RetencaoHome> getHome() async {
    final r = await _dio.get('/api/retencao/home');
    return RetencaoHome.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<RetencaoBasePage> listarBase({
    int page = 0,
    String? q,
    String? nivel,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/retencao/base',
      queryParameters: {
        'page': page,
        'size': basePageSize,
        if (query.isNotEmpty) 'q': query,
        if (nivel != null) 'nivel': nivel,
      },
    );
    return RetencaoBasePage.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  /// Tira o aluno da fila por um dia.
  Future<void> adiar(int alunoId) =>
      _dio.post('/api/alertas/aluno/$alunoId/resolver');
}
