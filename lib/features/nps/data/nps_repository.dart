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

  const NpsHomeBundle({required this.resumo, required this.recentes});

  factory NpsHomeBundle.fromJson(Map<String, dynamic> j) {
    final resumoJson = j['resumo'];
    return NpsHomeBundle(
      resumo:
          resumoJson is Map<String, dynamic>
              ? NpsResumo.fromJson(resumoJson)
              : NpsResumo(
                total: 0,
                npsScore: 0,
                media: 0,
                promotores: 0,
                detratores: 0,
                neutros: 0,
              ),
      recentes:
          ((j['recentes'] as List?) ?? const [])
              .map((e) => NpsItem.fromJson(e as Map<String, dynamic>))
              .toList(),
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

  /// BFF tipado — first paint da tela NPS (resumo + recentes).
  Future<NpsHomeBundle> getHome() async {
    final r = await _dio.get('/api/nps/home');
    return NpsHomeBundle.fromJson(r.data as Map<String, dynamic>);
  }
}
