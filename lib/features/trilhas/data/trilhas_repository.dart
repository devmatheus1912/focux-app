import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class TrilhasRepository {
  final Dio _dio;
  TrilhasRepository(ApiClient client) : _dio = client.dio;

  Future<List<Map<String, dynamic>>> listarPorAluno(int alunoId) async {
    final r = await _dio.get('/api/trilhas/aluno/$alunoId');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> criarTrilha(Map<String, dynamic> body) async {
    await _dio.post('/api/trilhas', data: body);
  }

  Future<void> concluirMarco(int marcoId) async {
    await _dio.patch('/api/trilhas/marcos/$marcoId/concluir');
  }
}
