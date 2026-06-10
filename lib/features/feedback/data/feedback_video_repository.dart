import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class FeedbackVideo {
  final int id;
  final int alunoId;
  final int? personalId;
  final int exercicioId;
  final String videoUrl;
  final String comentario;
  final DateTime criadoEm;
  final String? aiAnalise;
  final int? aiScore;
  final String? statusAnalise;

  FeedbackVideo({
    required this.id,
    required this.alunoId,
    this.personalId,
    required this.exercicioId,
    required this.videoUrl,
    required this.comentario,
    required this.criadoEm,
    this.aiAnalise,
    this.aiScore,
    this.statusAnalise,
  });

  factory FeedbackVideo.fromJson(Map<String, dynamic> j) => FeedbackVideo(
    id: j['id'] as int,
    alunoId: j['alunoId'] as int,
    personalId: j['personalId'] as int?,
    exercicioId: j['exercicioId'] as int,
    videoUrl: j['videoUrl'] as String,
    comentario: j['comentario'] as String? ?? '',
    criadoEm: DateTime.parse(j['criadoEm'] as String),
    aiAnalise: j['aiAnalise'] as String?,
    aiScore: j['aiScore'] as int?,
    statusAnalise: j['statusAnalise'] as String?,
  );
}

class FeedbackVideoRepository {
  final Dio _dio;

  FeedbackVideoRepository(ApiClient client) : _dio = client.dio;

  Future<List<FeedbackVideo>> listar() async {
    final r = await _dio.get('/api/feedback-videos');
    return (r.data as List).map((e) => FeedbackVideo.fromJson(e)).toList();
  }

  Future<List<FeedbackVideo>> listarPorAluno(int alunoId) async {
    final r = await _dio.get('/api/feedback-videos/aluno/$alunoId');
    return (r.data as List).map((e) => FeedbackVideo.fromJson(e)).toList();
  }

  Future<List<FeedbackVideo>> meus() async {
    final r = await _dio.get('/api/feedback-videos/me');
    return (r.data as List)
        .map((e) => FeedbackVideo.fromJson(e as Map<String, dynamic>))
        .toList();
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

  Future<FeedbackVideo> enviarMeu({
    required String videoUrl,
    required int exercicioId,
    String? comentario,
  }) async {
    final r = await _dio.post(
      '/api/feedback-videos/me',
      data: {
        'videoUrl': videoUrl,
        'exercicioId': exercicioId,
        'comentario': comentario,
      },
    );
    return FeedbackVideo.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> deletar(int id) async {
    await _dio.delete('/api/feedback-videos/$id');
  }

  Future<List<ExercicioOpcao>> exerciciosDisponiveis() async {
    final r = await _dio.get('/api/feedback-videos/me/exercicios-disponiveis');
    return (r.data as List)
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
