import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Exercicio {
  final int id;
  final String nome;
  final String? descricao;
  final String? musculoAlvo;
  final String? gifUrl;
  final String? categoria;
  final String? videoUrl;

  Exercicio({
    required this.id,
    required this.nome,
    this.descricao,
    this.musculoAlvo,
    this.gifUrl,
    this.categoria,
    this.videoUrl,
  });

  factory Exercicio.fromJson(Map<String, dynamic> json) => Exercicio(
        id: json['id'] as int,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        musculoAlvo: json['musculoAlvo'] as String?,
        gifUrl: json['gifUrl'] as String?,
        categoria: json['categoria'] as String?,
        videoUrl: json['videoUrl'] as String?,
      );
}

class ExercicioRepository {
  final Dio _dio;

  ExercicioRepository(ApiClient client) : _dio = client.dio;

  Future<List<Exercicio>> listar() async {
    final response = await _dio.get('/api/exercicios');
    final list = response.data as List<dynamic>;
    return list.map((e) => Exercicio.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Exercicio> buscar(int id) async {
    final response = await _dio.get('/api/exercicios/$id');
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercicio> criar({
    required String nome,
    String? descricao,
    String? musculoAlvo,
    String? categoria,
  }) async {
    final response = await _dio.post('/api/exercicios', data: {
      'nome': nome,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (musculoAlvo != null && musculoAlvo.isNotEmpty) 'musculoAlvo': musculoAlvo,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
    });
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }
}
