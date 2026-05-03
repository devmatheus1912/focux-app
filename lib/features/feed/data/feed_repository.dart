import '../../../core/api/api_client.dart';

class FeedPost {
  final int id;
  final String titulo;
  final String conteudo;
  final String? imagemUrl; // legacy
  final String? midiaUrl;
  final String? tipoPost; // TEXTO, IMAGEM, VIDEO, ENQUETE, DICA
  final bool fixado;
  final int totalCurtidas;
  final int totalComentarios;
  final String criadoEm;

  FeedPost({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.imagemUrl,
    this.midiaUrl,
    this.tipoPost,
    this.fixado = false,
    this.totalCurtidas = 0,
    this.totalComentarios = 0,
    required this.criadoEm,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
    id: json['id'],
    titulo: json['titulo'],
    conteudo: json['conteudo'],
    imagemUrl: json['imagemUrl'],
    midiaUrl: json['midiaUrl'],
    tipoPost: json['tipoPost'],
    fixado: json['fixado'] ?? false,
    totalCurtidas: json['totalCurtidas'] ?? 0,
    totalComentarios: json['totalComentarios'] ?? 0,
    criadoEm: json['criadoEm'] ?? '',
  );
}

class FeedComentario {
  final int id;
  final int alunoId;
  final String alunoNome;
  final String texto;
  final String criadoEm;

  FeedComentario({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    required this.texto,
    required this.criadoEm,
  });

  factory FeedComentario.fromJson(Map<String, dynamic> json) => FeedComentario(
    id: json['id'],
    alunoId: json['alunoId'],
    alunoNome: json['alunoNome'],
    texto: json['texto'],
    criadoEm: json['criadoEm'] ?? '',
  );
}

class FeedRepository {
  final ApiClient _client;
  FeedRepository(this._client);

  Future<List<FeedPost>> listarPersonal() async {
    final r = await _client.dio.get('/api/feed');
    return (r.data as List).map((e) => FeedPost.fromJson(e)).toList();
  }

  Future<List<FeedPost>> listarAluno() async {
    final r = await _client.dio.get('/api/feed/aluno');
    return (r.data as List).map((e) => FeedPost.fromJson(e)).toList();
  }

  Future<FeedPost> criar(
    String titulo,
    String conteudo, {
    String? tipoPost,
    String? midiaUrl,
  }) async {
    final r = await _client.dio.post(
      '/api/feed',
      data: {
        'titulo': titulo,
        'conteudo': conteudo,
        if (tipoPost != null) 'tipoPost': tipoPost,
        if (midiaUrl != null) 'midiaUrl': midiaUrl,
      },
    );
    return FeedPost.fromJson(r.data);
  }

  Future<void> deletar(int id) => _client.dio.delete('/api/feed/$id');

  Future<FeedPost> toggleFixar(int id) async {
    final r = await _client.dio.patch('/api/feed/$id/fixar');
    return FeedPost.fromJson(r.data);
  }

  Future<int> toggleCurtida(int postId) async {
    final r = await _client.dio.post('/api/feed/$postId/curtir');
    return r.data['totalCurtidas'];
  }

  Future<FeedComentario> comentar(int postId, String texto) async {
    final r = await _client.dio.post(
      '/api/feed/$postId/comentarios',
      data: {'texto': texto},
    );
    return FeedComentario.fromJson(r.data);
  }

  Future<List<FeedComentario>> listarComentarios(int postId) async {
    final r = await _client.dio.get('/api/feed/$postId/comentarios');
    return (r.data as List).map((e) => FeedComentario.fromJson(e)).toList();
  }
}
