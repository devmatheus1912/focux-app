import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NpsResumo {
  final int total;
  final double npsScore;
  final double media;
  final int promotores;
  final int detratores;
  final int neutros;

  NpsResumo({
    required this.total,
    required this.npsScore,
    required this.media,
    required this.promotores,
    required this.detratores,
    required this.neutros,
  });

  factory NpsResumo.fromJson(Map<String, dynamic> j) => NpsResumo(
    total: (j['total'] as num?)?.toInt() ?? 0,
    npsScore: (j['npsScore'] as num?)?.toDouble() ?? 0,
    media: (j['media'] as num?)?.toDouble() ?? 0,
    promotores: (j['promotores'] as num?)?.toInt() ?? 0,
    detratores: (j['detratores'] as num?)?.toInt() ?? 0,
    neutros: (j['neutros'] as num?)?.toInt() ?? 0,
  );
}

class NpsItem {
  final int id;
  final int score;
  final String? comentario;
  final String criadoEm;
  final int? alunoId;
  final String? alunoNome;

  NpsItem({
    required this.id,
    required this.score,
    required this.criadoEm,
    this.comentario,
    this.alunoId,
    this.alunoNome,
  });

  factory NpsItem.fromJson(Map<String, dynamic> j) => NpsItem(
    id: (j['id'] as num).toInt(),
    score: (j['score'] as num).toInt(),
    comentario: j['comentario'] as String?,
    criadoEm: j['criadoEm'] as String? ?? '',
    alunoId: (j['alunoId'] as num?)?.toInt(),
    alunoNome: j['alunoNome'] as String?,
  );
}

class NpsHomeBundle {
  final NpsResumo resumo;
  final List<NpsItem> recentes;
  final List<NpsItem> itens;
  final int page;
  final int totalItens;
  final bool hasNext;

  const NpsHomeBundle({
    required this.resumo,
    required this.recentes,
    this.itens = const [],
    this.page = 0,
    this.totalItens = 0,
    this.hasNext = false,
  });

  factory NpsHomeBundle.fromJson(Map<String, dynamic> j) {
    final resumoJson = j['resumo'];
    List<NpsItem> parse(String key) {
      final raw = j[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => NpsItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    final recentes = parse('recentes');
    final itens = parse('itens');
    return NpsHomeBundle(
      resumo:
          resumoJson is Map
              ? NpsResumo.fromJson(Map<String, dynamic>.from(resumoJson))
              : NpsResumo(
                total: 0,
                npsScore: 0,
                media: 0,
                promotores: 0,
                detratores: 0,
                neutros: 0,
              ),
      recentes: recentes,
      itens: itens.isEmpty ? recentes : itens,
      page: (j['page'] as num?)?.toInt() ?? 0,
      totalItens:
          (j['totalItens'] as num?)?.toInt() ??
          (itens.isEmpty ? recentes.length : itens.length),
      hasNext: j['hasNext'] == true,
    );
  }
}

class NpsRepository {
  final Dio _dio;
  NpsRepository(ApiClient c) : _dio = c.dio;

  Future<bool> deveResponder() async {
    final r = await _dio.get('/api/nps/deve-responder');
    return (r.data as Map<String, dynamic>)['deve'] as bool? ?? false;
  }

  Future<void> responder({
    required int score,
    String? comentario,
    String contexto = 'POS_TREINO',
  }) async {
    await _dio.post(
      '/api/nps',
      data: {'score': score, 'comentario': comentario, 'contexto': contexto},
    );
  }

  static const homePageSize = 20;

  Future<NpsHomeBundle> getHome({int page = 0, String? q}) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      '/api/nps/home',
      queryParameters: {
        'page': page,
        'size': homePageSize,
        if (query.isNotEmpty) 'q': query,
      },
    );
    return NpsHomeBundle.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
