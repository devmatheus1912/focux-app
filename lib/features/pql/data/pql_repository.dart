import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class PqlSnapshot {
  final int score;
  final String classificacao;
  final List<String> eventos;

  PqlSnapshot({
    required this.score,
    required this.classificacao,
    required this.eventos,
  });

  factory PqlSnapshot.fromJson(Map<String, dynamic> j) => PqlSnapshot(
    score: (j['score'] as num?)?.toInt() ?? 0,
    classificacao: j['classificacao'] as String? ?? 'EARLY',
    eventos:
        (j['eventos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [],
  );
}

class PqlRepository {
  final Dio _dio;
  PqlRepository(ApiClient c) : _dio = c.dio;

  Future<PqlSnapshot> me() async {
    final r = await _dio.get('/api/pql/me');
    return PqlSnapshot.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PqlSnapshot> registrar(String tipo, {String? metadata}) async {
    final r = await _dio.post(
      '/api/pql/eventos/$tipo',
      queryParameters: metadata != null ? {'metadata': metadata} : null,
    );
    return PqlSnapshot.fromJson(r.data as Map<String, dynamic>);
  }
}
