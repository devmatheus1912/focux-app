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
        dataCalculo: j['dataCalculo'] != null
            ? DateTime.tryParse(j['dataCalculo'] as String)
            : null,
      );
}

class RetencaoRepository {
  final Dio _dio;
  RetencaoRepository(ApiClient c) : _dio = c.dio;

  Future<List<RetencaoAlunoScore>> listarBase() async {
    final r = await _dio.get('/api/retencao/base');
    return (r.data as List<dynamic>)
        .map((e) => RetencaoAlunoScore.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
