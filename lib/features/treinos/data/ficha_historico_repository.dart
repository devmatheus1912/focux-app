import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/ficha_historico.dart';

/// Fichas anteriores de um aluno (guardadas quando a ficha inteira é trocada).
class FichaHistoricoRepository {
  FichaHistoricoRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<List<FichaHistorico>> listar(int alunoId) async {
    final response = await _dio.get('/api/alunos/$alunoId/rotina/historico');
    return (response.data as List)
        .whereType<Map>()
        .map((json) => FichaHistorico.fromJson(Map<String, dynamic>.from(json)))
        .toList(growable: false);
  }

  Future<FichaHistorico> buscar(int alunoId, int fichaId) async {
    final response = await _dio.get('/api/alunos/$alunoId/rotina/historico/$fichaId');
    return FichaHistorico.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  /// O backend copia as sessões que ainda existem, guarda a ficha atual e
  /// começa 8 semanas de validade.
  Future<UsoDaFichaAnterior> usar(
    int alunoId,
    int fichaId, {
    bool manterCargas = true,
  }) async {
    final response = await _dio.post(
      '/api/alunos/$alunoId/rotina/historico/$fichaId/usar',
      queryParameters: {'manterCargas': manterCargas},
    );
    return UsoDaFichaAnterior.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
