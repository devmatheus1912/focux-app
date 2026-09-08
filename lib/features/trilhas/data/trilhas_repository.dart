import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/trilha.dart';

class TrilhasRepository {
  TrilhasRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<TrilhaModel>> listarPorAluno(int alunoId) async {
    final response = await _dio.get('/api/trilhas/aluno/$alunoId');
    return TrilhaModel.parseList(response.data);
  }

  Future<List<TrilhaModel>> listarMinhas() async {
    final response = await _dio.get('/api/trilhas/minhas');
    return TrilhaModel.parseList(response.data);
  }

  Future<void> criarTrilha(NovaTrilhaRequest request) async {
    await _dio.post('/api/trilhas', data: request.toJson());
  }

  Future<void> concluirMarco({
    required int trilhaId,
    required int marcoId,
  }) async {
    await _dio.post('/api/trilhas/$trilhaId/marcos/$marcoId/concluir');
  }

  Future<void> atualizarProgresso({
    required int trilhaId,
    required double valor,
  }) async {
    await _dio.put(
      '/api/trilhas/$trilhaId/progresso',
      queryParameters: {'valor': valor},
    );
  }

  Future<void> deletar(int trilhaId) async {
    await _dio.delete('/api/trilhas/$trilhaId');
  }
}
