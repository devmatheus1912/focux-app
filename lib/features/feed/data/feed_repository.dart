import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

class FeedPost {
  final int id;
  final String titulo;
  final String conteudo;
  final String? imagemUrl; // legacy
  final String? midiaUrl;
  final String? tipoPost; // TEXTO, IMAGEM, VIDEO, ENQUETE, DICA
  final String? autorNome;
  final String? autorAvatarUrl;
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
    this.autorNome,
    this.autorAvatarUrl,
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
    autorNome:
        json['autorNome'] ??
        json['authorName'] ??
        json['nomePersonal'] ??
        json['personalNome'] ??
        json['criadoPorNome'],
    autorAvatarUrl:
        json['autorAvatarUrl'] ??
        json['authorAvatarUrl'] ??
        json['personalLogoUrl'] ??
        json['logoUrl'] ??
        json['criadoPorAvatarUrl'],
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
  final String? alunoFotoUrl;
  final String texto;
  final String criadoEm;

  FeedComentario({
    required this.id,
    required this.alunoId,
    required this.alunoNome,
    this.alunoFotoUrl,
    required this.texto,
    required this.criadoEm,
  });

  factory FeedComentario.fromJson(Map<String, dynamic> json) => FeedComentario(
    id: json['id'],
    alunoId: json['alunoId'],
    alunoNome: json['alunoNome'],
    alunoFotoUrl:
        json['alunoFotoUrl'] ??
        json['fotoUrl'] ??
        json['avatarUrl'] ??
        json['alunoAvatarUrl'] ??
        json['profilePhotoUrl'],
    texto: json['texto'] ?? json['conteudo'] ?? '',
    criadoEm: json['criadoEm'] ?? '',
  );
}

class FeedRepository {
  final ApiClient _client;
  FeedRepository(this._client);

  Future<Pagina<FeedPost>> listarPersonalPagina({
    String? cursor,
    String? q,
    String? tipo,
    bool? fixado,
  }) async {
    final query = q?.trim();
    final r = await _client.dio.get(
      '/api/feed',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (query != null && query.isNotEmpty) 'q': query,
        if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
        if (fixado != null) 'fixado': fixado,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/feed devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => FeedPost.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<Pagina<FeedPost>> listarAlunoPagina({
    String? cursor,
    String? q,
    String? tipo,
    bool? fixado,
  }) async {
    final query = q?.trim();
    final r = await _client.dio.get(
      '/api/feed/aluno',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (query != null && query.isNotEmpty) 'q': query,
        if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
        if (fixado != null) 'fixado': fixado,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET /api/feed/aluno devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => FeedPost.fromJson(Map<String, dynamic>.from(item as Map)),
    );
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
      data: {'conteudo': texto, 'texto': texto},
    );
    return FeedComentario.fromJson(r.data);
  }

  Future<Pagina<FeedComentario>> listarComentarios(
    int postId, {
    String? cursor,
  }) async {
    final r = await _client.dio.get(
      '/api/feed/$postId/comentarios',
      queryParameters: {if (cursor != null && cursor.isNotEmpty) 'cursor': cursor},
    );
    if (r.data is! Map) {
      throw const FormatException(
        'GET /api/feed/{id}/comentarios devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(r.data as Map),
      (item) => FeedComentario.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }
}
