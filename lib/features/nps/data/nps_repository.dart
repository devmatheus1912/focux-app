import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class NpsResumo {
  final int total;
  final double npsScore;
  final double media;
  final int promotores;

  NpsResumo({
    required this.total,
    required this.npsScore,
    required this.media,
    required this.promotores,
  });

  factory NpsResumo.fromJson(Map<String, dynamic> j) => NpsResumo(
    total: (j['total'] as num?)?.toInt() ?? 0,
    npsScore: (j['npsScore'] as num?)?.toDouble() ?? 0,
    media: (j['media'] as num?)?.toDouble() ?? 0,
    promotores: (j['promotores'] as num?)?.toInt() ?? 0,
  );
}

class NpsItem {
  final int id;
  final int score;
  final String? comentario;
  final String criadoEm;

  NpsItem({
    required this.id,
    required this.score,
    required this.criadoEm,
    this.comentario,
  });

  factory NpsItem.fromJson(Map<String, dynamic> j) => NpsItem(
    id: (j['id'] as num).toInt(),
    score: (j['score'] as num).toInt(),
    comentario: j['comentario'] as String?,
    criadoEm: j['criadoEm'] as String? ?? '',
  );
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
    await _dio.post('/api/nps', data: {
      'score': score,
      'comentario': comentario,
      'contexto': contexto,
    });
  }

  Future<NpsResumo> resumo() async {
    final r = await _dio.get('/api/nps/resumo');
    return NpsResumo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<NpsItem>> recentes() async {
    final r = await _dio.get('/api/nps/recentes');
    return (r.data as List)
        .map((e) => NpsItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
