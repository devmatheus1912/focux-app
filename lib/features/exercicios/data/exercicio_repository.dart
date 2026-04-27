import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Exercicio {
  final int id;
  final String nome;
  final String? descricao;
  final String? musculoAlvo;
  final String? gifUrl;
  final String? categoria;
  final String? equipamento;
  final String? nivel;
  final String? mecanica;
  final String? objetivo;
  final String? videoUrl;
  final String? tags;
  final bool favoritado;

  Exercicio({
    required this.id,
    required this.nome,
    this.descricao,
    this.musculoAlvo,
    this.gifUrl,
    this.categoria,
    this.equipamento,
    this.nivel,
    this.mecanica,
    this.objetivo,
    this.videoUrl,
    this.tags,
    this.favoritado = false,
  });

  factory Exercicio.fromJson(Map<String, dynamic> json) => Exercicio(
        id: json['id'] as int,
        nome: json['nome'] as String,
        descricao: json['descricao'] as String?,
        musculoAlvo: json['musculoAlvo'] as String?,
        gifUrl: json['gifUrl'] as String?,
        categoria: json['categoria'] as String?,
        equipamento: json['equipamento'] as String?,
        nivel: json['nivel'] as String?,
        mecanica: json['mecanica'] as String?,
        objetivo: json['objetivo'] as String?,
        videoUrl: json['videoUrl'] as String?,
        tags: json['tags'] as String?,
        favoritado: json['favoritado'] as bool? ?? false,
      );
}

class ExercicioRepository {
  final Dio _dio;

  ExercicioRepository(ApiClient client) : _dio = client.dio;

  Future<List<Exercicio>> listar({
    String? categoria,
    String? tag,
    bool? favoritos,
  }) async {
    final queryParams = <String, dynamic>{};
    if (categoria != null && categoria.isNotEmpty) queryParams['categoria'] = categoria;
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    if (favoritos == true) queryParams['favoritos'] = 'true';

    final response = await _dio.get('/api/exercicios',
        queryParameters: queryParams.isNotEmpty ? queryParams : null);
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
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    String? tags,
    String? observacoes,
  }) async {
    final response = await _dio.post('/api/exercicios', data: {
      'nome': nome,
      if (descricao != null && descricao.isNotEmpty) 'descricao': descricao,
      if (musculoAlvo != null && musculoAlvo.isNotEmpty) 'musculoAlvo': musculoAlvo,
      if (categoria != null && categoria.isNotEmpty) 'categoria': categoria,
      if (equipamento != null && equipamento.isNotEmpty) 'equipamento': equipamento,
      if (nivel != null && nivel.isNotEmpty) 'nivel': nivel,
      if (mecanica != null && mecanica.isNotEmpty) 'mecanica': mecanica,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (observacoes != null && observacoes.isNotEmpty) 'observacoes': observacoes,
    });
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Exercicio> uploadVideo({
    required int id,
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final response = await _dio.post('/api/exercicios/$id/video', data: form);
    return Exercicio.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> favoritarExercicio(int id) async {
    await _dio.post('/api/exercicios/$id/favoritar');
  }

  Future<void> desfavoritarExercicio(int id) async {
    await _dio.delete('/api/exercicios/$id/favoritar');
  }
}
