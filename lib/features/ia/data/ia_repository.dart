import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';

class IaOperationalException implements Exception {
  final String message;
  final String? reference;
  final int? statusCode;
  final bool retryable;

  const IaOperationalException({
    required this.message,
    this.reference,
    this.statusCode,
    required this.retryable,
  });

  factory IaOperationalException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final payload = error.response?.data;
    final rawMessage =
        payload is Map
            ? (payload['erro'] ?? payload['message'])?.toString()
            : null;
    final fullMessage =
        rawMessage?.trim().isNotEmpty == true
            ? rawMessage!.trim()
            : status == 429
            ? 'Limite de IA atingido agora. Tente novamente em instantes.'
            : status == null
            ? 'Sem conexao com a IA agora.'
            : 'IA temporariamente indisponivel.';
    final reference = _extractReference(fullMessage);
    // Strip "Ref: <id>" from message body so UI layer can render it once.
    final message =
        reference == null
            ? fullMessage
            : fullMessage
                .replaceAll(RegExp(r'\s*Ref:\s*[a-zA-Z0-9-]+\.?'), '')
                .trim();
    final retryable =
        status == null || status == 408 || status == 429 || status >= 500;
    return IaOperationalException(
      message: message,
      reference: reference,
      statusCode: status,
      retryable: retryable,
    );
  }

  @override
  String toString() => message;
}

class IaRepository {
  final Dio _dio;
  static final _iaOpts = Options(receiveTimeout: const Duration(seconds: 60));
  IaRepository(ApiClient c) : _dio = c.dio;

  Future<String> gerarTreino(
    int alunoId, {
    String? objetivo,
    String? nivelAtividade,
    String? restricoes,
    int diasPorSemana = 3,
    String? equipamentos,
  }) async {
    final r = await _dio.post(
      '/api/ia/gerar-treino',
      options: _iaOpts,
      data: {
        'alunoId': alunoId,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (nivelAtividade != null && nivelAtividade.isNotEmpty)
          'nivelAtividade': nivelAtividade,
        if (restricoes != null && restricoes.isNotEmpty)
          'restricoes': restricoes,
        'diasPorSemana': diasPorSemana,
        if (equipamentos != null && equipamentos.isNotEmpty)
          'equipamentosDisponiveis': equipamentos,
      },
    );
    return r.data['resposta'] as String;
  }

  Future<String> gerarDieta(
    int alunoId, {
    String? objetivo,
    int? pesoKg,
    int? alturaCm,
    String? restricoes,
    int? caloriasAlvo,
  }) async {
    final r = await _dio.post(
      '/api/ia/gerar-dieta',
      options: _iaOpts,
      data: {
        'alunoId': alunoId,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (pesoKg != null) 'pesoKg': pesoKg,
        if (alturaCm != null) 'alturaCm': alturaCm,
        if (restricoes != null && restricoes.isNotEmpty)
          'restricoesAlimentares': restricoes,
        if (caloriasAlvo != null) 'caloriasAlvo': caloriasAlvo,
      },
    );
    return r.data['resposta'] as String;
  }

  Future<String> chat(String mensagem, {int? alunoId}) async {
    final r = await _dio.post(
      '/api/ia/chat',
      options: _iaOpts,
      data: {'mensagem': mensagem, if (alunoId != null) 'alunoId': alunoId},
    );
    return r.data['resposta'] as String;
  }

  Future<String> progressaoCarga(
    int alunoId, {
    String? objetivo,
    String? historicoTreinos,
  }) async {
    final r = await _dio.post(
      '/api/ia/progressao-carga',
      options: _iaOpts,
      data: {
        'alunoId': alunoId,
        if (objetivo != null && objetivo.isNotEmpty) 'objetivo': objetivo,
        if (historicoTreinos != null && historicoTreinos.isNotEmpty)
          'historicoTreinos': historicoTreinos,
      },
    );
    return r.data['resposta'] as String;
  }

  // ── Copiloto ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> resumoSemanal() async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/resumo-semanal',
        options: _iaOpts,
      );
      return r.data as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> proximaAcao(int alunoId) async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/proxima-acao/$alunoId',
        options: _iaOpts,
      );
      return r.data as Map<String, dynamic>;
    });
  }

  Future<String> analisePerformance(int alunoId) async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/analise-performance/$alunoId',
        options: _iaOpts,
      );
      return r.data['resposta'] as String;
    });
  }

  Future<List<Map<String, dynamic>>> insights({
    int? alunoId,
    String? mode,
  }) async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/insights',
        options: _iaOpts,
        queryParameters: {
          if (alunoId != null) 'alunoId': alunoId,
          if (mode != null && mode.isNotEmpty) 'mode': mode,
        },
      );
      return (r.data as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    });
  }

  Future<Map<String, dynamic>> salvarAcaoCopiloto({
    required int alunoId,
    required String acao,
    String? motivo,
    String? modo,
  }) async {
    return _withIaErrorContext(() async {
      final r = await _dio.post(
        '/api/ia/copiloto/acoes',
        data: {
          'alunoId': alunoId,
          'acao': acao,
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
          if (modo != null && modo.isNotEmpty) 'modo': modo,
        },
      );
      return r.data as Map<String, dynamic>;
    });
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
    final r = await _dio.post(
      '/api/ia/confirmar-publicar/$alunoId',
      options: _iaOpts,
    );
    return r.data['confirmado'] == true;
  }
}

Future<T> _withIaErrorContext<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on DioException catch (error) {
    throw IaOperationalException.fromDio(error);
  }
}

String? _extractReference(String message) {
  final match = RegExp(r'Ref:\s*([a-zA-Z0-9-]+)').firstMatch(message);
  return match?.group(1);
}
