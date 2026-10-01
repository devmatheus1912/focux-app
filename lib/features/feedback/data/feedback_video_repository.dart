import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/pagina.dart';

class FeedbackVideo {
  final int id;
  final int alunoId;
  final int? personalId;
  final int exercicioId;
  final String videoUrl;
  final String comentario;
  final DateTime criadoEm;
  final String? respostaPersonal;
  final DateTime? respondidoEm;
  final String? status;

  bool get respondido => (respostaPersonal ?? '').trim().isNotEmpty;

  FeedbackVideo({
    required this.id,
    required this.alunoId,
    this.personalId,
    required this.exercicioId,
    required this.videoUrl,
    required this.comentario,
    required this.criadoEm,
    this.respostaPersonal,
    this.respondidoEm,
    this.status,
  });

  factory FeedbackVideo.fromJson(Map<String, dynamic> j) => FeedbackVideo(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    personalId: j['personalId'] as int?,
    exercicioId: j['exercicioId'] as int,
    videoUrl: j['videoUrl'] as String,
    comentario: j['comentario'] as String? ?? '',
    criadoEm: DateTime.parse(j['criadoEm'] as String),
    respostaPersonal: j['respostaPersonal'] as String?,
    respondidoEm: j['respondidoEm'] == null
        ? null
        : DateTime.parse(j['respondidoEm'] as String),
    status: j['status'] as String?,
  );
}

class FeedbackVideoRepository {
  final Dio _dio;

  FeedbackVideoRepository(ApiClient client) : _dio = client.dio;

  Future<Pagina<FeedbackVideo>> listarPagina({
    int page = 0,
    int size = 20,
    int? alunoId,
    String? q,
  }) async {
    final path =
        alunoId == null
            ? '/api/feedback-videos'
            : '/api/feedback-videos/aluno/$alunoId';
    return _pagina(path, page: page, size: size, q: q);
  }

  Future<List<FeedbackVideo>> listar() async {
    return (await listarPagina()).content;
  }

  Future<List<FeedbackVideo>> listarPorAluno(int alunoId) async {
    return (await listarPagina(alunoId: alunoId)).content;
  }

  Future<Pagina<FeedbackVideo>> listarMeus({
    int page = 0,
    int size = 20,
    String? q,
  }) {
    return _pagina('/api/feedback-videos/me', page: page, size: size, q: q);
  }

  Future<Pagina<FeedbackVideo>> _pagina(
    String path, {
    int page = 0,
    int size = 20,
    String? q,
  }) async {
    final query = q?.trim() ?? '';
    final r = await _dio.get(
      path,
      queryParameters: {
        'page': page,
        'size': size,
        if (query.isNotEmpty) 'q': query,
      },
    );
    final data = r.data;
    if (data is! Map) {
      throw FormatException(
        'GET $path devolve Pagina, não lista crua.',
      );
    }
    return Pagina.fromJson(
      Map<String, dynamic>.from(data),
      (item) => FeedbackVideo.fromJson(Map<String, dynamic>.from(item as Map)),
    );
  }

  Future<FeedbackVideo> registrar({
    required int alunoId,
    required int exercicioId,
    required String videoUrl,
    required String comentario,
  }) async {
    final r = await _dio.post(
      '/api/feedback-videos',
      data: {
        'alunoId': alunoId,
        'exercicioId': exercicioId,
        'videoUrl': videoUrl,
        'comentario': comentario,
      },
    );
    return FeedbackVideo.fromJson(r.data);
  }

  Future<FeedbackVideo> responder(int id, String resposta) async {
    final r = await _dio.put(
      '/api/feedback-videos/$id/resposta',
      data: {'resposta': resposta},
    );
    return FeedbackVideo.fromJson(Map<String, dynamic>.from(r.data as Map));
  }

  Future<void> deletar(int id) async {
    await _dio.delete('/api/feedback-videos/$id');
  }

  Future<List<ExercicioOpcao>> exerciciosDisponiveisParaAluno(int alunoId) async {
    final r = await _dio.get('/api/feedback-videos/aluno/$alunoId/exercicios');
    return _parseExercicioOpcoes(r.data);
  }

  List<ExercicioOpcao> _parseExercicioOpcoes(Object? data) {
    return (data as List)
        .map((e) => ExercicioOpcao.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class ExercicioOpcao {
  final int id;
  final String nome;

  ExercicioOpcao({required this.id, required this.nome});

  factory ExercicioOpcao.fromJson(Map<String, dynamic> j) => ExercicioOpcao(
    id: (j['id'] as num).toInt(),
    nome: j['nome'] as String? ?? '',
  );
}
