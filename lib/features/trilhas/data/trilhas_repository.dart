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

  Future<TrilhaModel> criarTrilha(NovaTrilhaRequest request) async {
    final r = await _dio.post('/api/trilhas', data: request.toJson());
    return _trilha(r.data);
  }

  Future<TrilhaModel> editar({
    required int trilhaId,
    required String titulo,
    String? descricao,
    DateTime? dataFim,
  }) async {
    final r = await _dio.put(
      '/api/trilhas/$trilhaId',
      data: {
        'titulo': titulo,
        'descricao': descricao,
        'dataFim': dataFim == null ? null : trilhaIsoDia(dataFim),
      },
    );
    return _trilha(r.data);
  }

  Future<TrilhaModel> adicionarMarco({
    required int trilhaId,
    required String titulo,
  }) async {
    final r = await _dio.post(
      '/api/trilhas/$trilhaId/marcos',
      data: {'titulo': titulo},
    );
    return _trilha(r.data);
  }

  Future<TrilhaModel> concluirMarco({
    required int trilhaId,
    required int marcoId,
  }) async {
    final r = await _dio.post('/api/trilhas/$trilhaId/marcos/$marcoId/concluir');
    return _trilha(r.data);
  }

  /// Desfaz uma etapa marcada por engano (personal ou aluno).
  Future<TrilhaModel> reabrirMarco({
    required int trilhaId,
    required int marcoId,
  }) async {
    final r = await _dio.post('/api/trilhas/$trilhaId/marcos/$marcoId/reabrir');
    return _trilha(r.data);
  }

  Future<TrilhaModel> removerMarco({
    required int trilhaId,
    required int marcoId,
  }) async {
    final r = await _dio.delete('/api/trilhas/$trilhaId/marcos/$marcoId');
    return _trilha(r.data);
  }

  Future<void> deletar(int trilhaId) async {
    await _dio.delete('/api/trilhas/$trilhaId');
  }

  TrilhaModel _trilha(dynamic data) =>
      TrilhaModel.fromJson(Map<String, dynamic>.from(data as Map));
}
