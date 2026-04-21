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

  FeedbackVideo({
    required this.id,
    required this.alunoId,
    this.personalId,
    required this.exercicioId,
    required this.videoUrl,
    required this.comentario,
    required this.criadoEm,
  });

  factory FeedbackVideo.fromJson(Map<String, dynamic> j) => FeedbackVideo(
        id: j['id'] as int,
        alunoId: j['alunoId'] as int,
        personalId: j['personalId'] as int?,
        exercicioId: j['exercicioId'] as int,
        videoUrl: j['videoUrl'] as String,
        comentario: j['comentario'] as String,
        criadoEm: DateTime.parse(j['criadoEm'] as String),
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

  Future<FeedbackVideo> registrar({
    required int alunoId,
    required int exercicioId,
    required String videoUrl,
    required String comentario,
  }) async {
    final r = await _dio.post('/api/feedback-videos', data: {
      'alunoId': alunoId,
      'exercicioId': exercicioId,
      'videoUrl': videoUrl,
      'comentario': comentario,
    });
    return FeedbackVideo.fromJson(r.data);
  }

  Future<void> deletar(int id) async {
    await _dio.delete('/api/feedback-videos/$id');
  }
}
