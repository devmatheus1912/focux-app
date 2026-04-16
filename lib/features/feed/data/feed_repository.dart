import '../../../core/api/api_client.dart';

class FeedPost {
  final int id;
  final String titulo;
  final String conteudo;
  final String? imagemUrl;
  final String criadoEm;

  FeedPost({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.imagemUrl,
    required this.criadoEm,
  });

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
        id: json['id'],
        titulo: json['titulo'],
        conteudo: json['conteudo'],
        imagemUrl: json['imagemUrl'],
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

  Future<FeedPost> criar(String titulo, String conteudo, {String? imagemUrl}) async {
    final r = await _client.dio.post('/api/feed', data: {
      'titulo': titulo,
      'conteudo': conteudo,
      if (imagemUrl != null) 'imagemUrl': imagemUrl,
    });
    return FeedPost.fromJson(r.data);
  }

  Future<void> deletar(int id) => _client.dio.delete('/api/feed/$id');
}
