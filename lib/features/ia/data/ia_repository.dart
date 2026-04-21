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

  Future<String> progressaoCarga(int alunoId, {String? objetivo, String? historicoTreinos}) async {
    final r = await _dio.post('/api/ia/progressao-carga', data: {
      'alunoId': alunoId,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (historicoTreinos != null && historicoTreinos.isNotEmpty) 'historicoTreinos': historicoTreinos,
    });
    return r.data['resposta'] as String;
  }

  // ── Copiloto ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resumoSemanal() async {
    final r = await _dio.get('/api/ia/copiloto/resumo-semanal');
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> proximaAcao(int alunoId) async {
    final r = await _dio.get('/api/ia/copiloto/proxima-acao/$alunoId');
    return r.data as Map<String, dynamic>;
  }

  Future<String> analisePerformance(int alunoId) async {
    final r = await _dio.get('/api/ia/copiloto/analise-performance/$alunoId');
    return r.data['resposta'] as String;
  }

  Future<List<Map<String, dynamic>>> insights() async {
    final r = await _dio.get('/api/ia/copiloto/insights');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  // ── Progressão sugestões ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> sugestoesProgressao() async {
    final r = await _dio.get('/api/ia/progressao/sugestoes');
    return (r.data as List).cast<Map<String, dynamic>>();
  }

  Future<void> aceitarSugestao(int id) async {
    await _dio.post('/api/ia/progressao/sugestoes/$id/aceitar');
  }

  Future<void> rejeitarSugestao(int id) async {
    await _dio.post('/api/ia/progressao/sugestoes/$id/rejeitar');
  }
}
