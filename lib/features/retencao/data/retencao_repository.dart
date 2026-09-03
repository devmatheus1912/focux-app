import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class RetencaoAlunoScore {
  final int alunoId;
  final String alunoNome;
  final int scoreAtual;
  final int? scoreAnterior;
  final int delta;
  final String riscoChurn;
  final DateTime? dataCalculo;

  RetencaoAlunoScore({
    required this.alunoId,
    required this.alunoNome,
    required this.scoreAtual,
    this.scoreAnterior,
    required this.delta,
    required this.riscoChurn,
    this.dataCalculo,
  });

  factory RetencaoAlunoScore.fromJson(Map<String, dynamic> j) =>
      RetencaoAlunoScore(
        alunoId: (j['alunoId'] as num).toInt(),
        alunoNome: j['alunoNome'] as String? ?? 'Aluno',
        scoreAtual: (j['scoreAtual'] as num?)?.toInt() ?? 0,
        scoreAnterior: (j['scoreAnterior'] as num?)?.toInt(),
        delta: (j['delta'] as num?)?.toInt() ?? 0,
        riscoChurn: j['riscoChurn'] as String? ?? 'MEDIO',
        dataCalculo:
            j['dataCalculo'] != null
                ? DateTime.tryParse(j['dataCalculo'] as String)
                : null,
      );
}

class RetencaoHome {
  const RetencaoHome({
    required this.alto,
    required this.medio,
    required this.saudavel,
    required this.top3,
    this.fetchedAt,
  });

  final int alto;
  final int medio;
  final int saudavel;
  final List<RetencaoAlunoScore> top3;
  final DateTime? fetchedAt;

  bool get isEmpty => alto == 0 && medio == 0 && saudavel == 0 && top3.isEmpty;

  factory RetencaoHome.fromJson(Map<String, dynamic> j) {
    return RetencaoHome(
      alto: (j['alto'] as num?)?.toInt() ?? 0,
      medio: (j['medio'] as num?)?.toInt() ?? 0,
      saudavel: (j['saudavel'] as num?)?.toInt() ?? 0,
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

class RetencaoRepository {
  final Dio _dio;
  RetencaoRepository(ApiClient c) : _dio = c.dio;

  Future<RetencaoHome> getHome() async {
    final r = await _dio.get('/api/retencao/home');
    return RetencaoHome.fromJson(Map<String, dynamic>.from(r.data as Map));
  }
}
