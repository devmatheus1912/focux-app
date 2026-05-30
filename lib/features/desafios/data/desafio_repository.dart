import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Desafio {
  final int id;
  final String titulo;
  final String? descricao;
  final String tipo;
  final int metaPontos;

  Desafio({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.metaPontos,
    this.descricao,
  });

  factory Desafio.fromJson(Map<String, dynamic> j) => Desafio(
    id: (j['id'] as num).toInt(),
    titulo: j['titulo'] as String? ?? '',
    descricao: j['descricao'] as String?,
    tipo: j['tipo'] as String? ?? 'HABITOS',
    metaPontos: (j['metaPontos'] as num?)?.toInt() ?? 100,
  );
}

class DesafioRepository {
  final Dio _dio;
  DesafioRepository(ApiClient c) : _dio = c.dio;

  Future<List<Desafio>> listar() async {
    final r = await _dio.get('/api/desafios');
    return (r.data as List).map((e) => Desafio.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Desafio> criar({required String titulo, String? descricao}) async {
    final r = await _dio.post('/api/desafios', data: {'titulo': titulo, 'descricao': descricao});
    return Desafio.fromJson(r.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> leaderboard(int id) async {
    final r = await _dio.get('/api/desafios/$id/leaderboard');
    return (r.data as List).cast<Map<String, dynamic>>();
  }
}
