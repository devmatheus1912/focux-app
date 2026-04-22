import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class IaRepository {
  final Dio _dio;
  static final _iaOpts = Options(receiveTimeout: const Duration(seconds: 60));
  IaRepository(ApiClient c) : _dio = c.dio;

  Future<String> gerarTreino(int alunoId, {String? objetivo, String? nivelAtividade,
    String? restricoes, int diasPorSemana = 3, String? equipamentos}) async {
    final r = await _dio.post('/api/ia/gerar-treino', options: _iaOpts, data: {
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
    final r = await _dio.post('/api/ia/gerar-dieta', options: _iaOpts, data: {
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
    final r = await _dio.post('/api/ia/chat', options: _iaOpts, data: {
      'mensagem': mensagem,
      if (alunoId != null) 'alunoId': alunoId,
    });
    return r.data['resposta'] as String;
  }

  Future<String> progressaoCarga(int alunoId, {String? objetivo, String? historicoTreinos}) async {
    final r = await _dio.post('/api/ia/progressao-carga', options: _iaOpts, data: {
      'alunoId': alunoId,
      if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
      if (historicoTreinos != null && historicoTreinos.isNotEmpty) 'historicoTreinos': historicoTreinos,
    });
    return r.data['resposta'] as String;
  }

  // ── Copiloto ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resumoSemanal() async {
    final r = await _dio.get('/api/ia/copiloto/resumo-semanal', options: _iaOpts);
    return r.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> proximaAcao(int alunoId) async {
    final r = await _dio.get('/api/ia/copiloto/proxima-acao/$alunoId', options: _iaOpts);
    return r.data as Map<String, dynamic>;
  }

  Future<String> analisePerformance(int alunoId) async {
    final r = await _dio.get('/api/ia/copiloto/analise-performance/$alunoId', options: _iaOpts);
    return r.data['resposta'] as String;
  }

  Future<List<Map<String, dynamic>>> insights() async {
    final r = await _dio.get('/api/ia/copiloto/insights', options: _iaOpts);
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

  Future<bool> confirmarPublicar(int alunoId) async {
    final r = await _dio.post('/api/ia/confirmar-publicar/$alunoId', options: _iaOpts);
    return r.data['confirmado'] == true;
  }
}
