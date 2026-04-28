import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class Exercicio {
  final int id;
  final String nome;
  final String? descricao;
  final String? musculoAlvo;
  final String? gifUrl;
  final String? thumbnailUrl;
  final String? videoSource;
  final String? licenseStatus;
  final String? categoria;
  final String? equipamento;
  final String? nivel;
  final String? mecanica;
  final String? objetivo;
  final String? errosComuns;
  final String? contraindicacoes;
  final String? substitutos;
  final String? videoUrl;
  final String? tags;
  final bool favoritado;

  Exercicio({
    required this.id,
    required this.nome,
    this.descricao,
    this.musculoAlvo,
    this.gifUrl,
    this.thumbnailUrl,
    this.videoSource,
    this.licenseStatus,
    this.categoria,
    this.equipamento,
    this.nivel,
    this.mecanica,
    this.objetivo,
    this.errosComuns,
    this.contraindicacoes,
    this.substitutos,
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
        thumbnailUrl: json['thumbnailUrl'] as String?,
        videoSource: json['videoSource'] as String?,
        licenseStatus: json['licenseStatus'] as String?,
        categoria: json['categoria'] as String?,
        equipamento: json['equipamento'] as String?,
        nivel: json['nivel'] as String?,
        mecanica: json['mecanica'] as String?,
        objetivo: json['objetivo'] as String?,
        errosComuns: json['errosComuns'] as String?,
        contraindicacoes: json['contraindicacoes'] as String?,
        substitutos: json['substitutos'] as String?,
        videoUrl: json['videoUrl'] as String?,
        tags: json['tags'] as String?,
        favoritado: json['favoritado'] as bool? ?? false,
      );
}

class ExercicioRepository {
  final Dio _dio;

  ExercicioRepository(ApiClient client) : _dio = client.dio;

  Future<List<Exercicio>> listar({
    String? nome,
    String? categoria,
    String? tag,
    String? musculoAlvo,
    String? equipamento,
    String? nivel,
    String? mecanica,
    String? objetivo,
    bool? hasVideo,
    String? videoSource,
    String? licenseStatus,
    bool? favoritos,
  }) async {
    final queryParams = <String, dynamic>{};
    if (nome != null && nome.isNotEmpty) queryParams['nome'] = nome;
    if (categoria != null && categoria.isNotEmpty) queryParams['categoria'] = categoria;
    if (tag != null && tag.isNotEmpty) queryParams['tag'] = tag;
    if (musculoAlvo != null && musculoAlvo.isNotEmpty) queryParams['musculoAlvo'] = musculoAlvo;
    if (equipamento != null && equipamento.isNotEmpty) queryParams['equipamento'] = equipamento;
    if (nivel != null && nivel.isNotEmpty) queryParams['nivel'] = nivel;
    if (mecanica != null && mecanica.isNotEmpty) queryParams['mecanica'] = mecanica;
    if (objetivo != null && objetivo.isNotEmpty) queryParams['objetivo'] = objetivo;
    if (hasVideo == true) queryParams['hasVideo'] = 'true';
    if (videoSource != null && videoSource.isNotEmpty) queryParams['videoSource'] = videoSource;
    if (licenseStatus != null && licenseStatus.isNotEmpty) queryParams['licenseStatus'] = licenseStatus;
    if (favoritos == true) queryParams['favoritos'] = 'true';
    queryParams['page'] = 0;
    queryParams['size'] = 80;
    queryParams['sort'] = 'nome,asc';
    final response = await _dio.get('/api/exercicios/v2', queryParameters: queryParams);
    final data = response.data;
    final list = data is Map<String, dynamic> ? data['content'] as List<dynamic> : data as List<dynamic>;
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
    String? errosComuns,
    String? contraindicacoes,
    String? substitutos,
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
      if (errosComuns != null && errosComuns.isNotEmpty) 'errosComuns': errosComuns,
      if (contraindicacoes != null && contraindicacoes.isNotEmpty) 'contraindicacoes': contraindicacoes,
      if (substitutos != null && substitutos.isNotEmpty) 'substitutos': substitutos,
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

  Future<int> importarSeedV1() async {
    final response = await _dio.post('/api/exercicios/importar/seed/v1');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return (data['importados'] as int?) ?? (data['total'] as int?) ?? 0;
    }
    return 0;
  }

  Future<void> favoritarExercicio(int id) async {
    await _dio.post('/api/exercicios/$id/favoritar');
  }

  Future<void> desfavoritarExercicio(int id) async {
    await _dio.delete('/api/exercicios/$id/favoritar');
  }
}
