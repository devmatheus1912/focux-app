import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/trilha.dart';

class TrilhasRepository {
  TrilhasRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<TrilhaLista> listarPorAluno(int alunoId, {int page = 0, int size = 50}) async {
    final response = await _dio.get(
      '/api/trilhas/aluno/$alunoId',
      queryParameters: {'page': page, 'size': size},
    );
    return TrilhaLista.fromJson(response.data);
  }

  Future<TrilhaLista> listarMinhas({int page = 0, int size = 50}) async {
    final response = await _dio.get(
      '/api/trilhas/minhas',
      queryParameters: {'page': page, 'size': size},
    );
    return TrilhaLista.fromJson(response.data);
  }

  Future<void> criarTrilha(NovaTrilhaRequest request) async {
    await _dio.post('/api/trilhas', data: request.toJson());
  }

  Future<void> adicionarMarco({
    required int trilhaId,
    required String titulo,
  }) async {
    await _dio.post('/api/trilhas/$trilhaId/marcos', data: {'titulo': titulo});
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
