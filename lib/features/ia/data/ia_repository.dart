import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class IaRepository {
  final Dio _dio;
  IaRepository(ApiClient c) : _dio = c.dio;

  Future<String> gerarTreino(int alunoId, {String? objetivo, String? nivelAtividade,
    String? restricoes, int diasPorSemana = 3, String? equipamentos}) async {
    final r = await _dio.post('/api/ia/gerar-treino', data: {
      'alunoId': alunoId,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (nivelAtividade != null && nivelAtividade.isNotEmpty) 'nivelAtividade': nivelAtividade,
      if (restricoes != null && restricoes.isNotEmpty) 'restricoes': restricoes,
      'diasPorSemana': diasPorSemana,
      if (equipamentos != null && equipamentos.isNotEmpty) 'equipamentosDisponiveis': equipamentos,
    });
    return r.data['resposta'] as String;
  }

  Future<String> gerarDieta(int alunoId, {String? objetivo, int? pesoKg, int? alturaCm,
    String? restricoes, int? caloriasAlvo}) async {
    final r = await _dio.post('/api/ia/gerar-dieta', data: {
      'alunoId': alunoId,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (pesoKg != null) 'pesoKg': pesoKg,
      if (alturaCm != null) 'alturaCm': alturaCm,
      if (restricoes != null && restricoes.isNotEmpty) 'restricoesAlimentares': restricoes,
      if (caloriasAlvo != null) 'caloriasAlvo': caloriasAlvo,
    });
    return r.data['resposta'] as String;
  }

  Future<String> chat(String mensagem, {int? alunoId}) async {
    final r = await _dio.post('/api/ia/chat', data: {
      'mensagem': mensagem,
      if (alunoId != null) 'alunoId': alunoId,
    });
    return r.data['resposta'] as String;
  }
}
