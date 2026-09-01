import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../subscription/models/subscription_plan.dart';
import '../models/ia_copilot_insight.dart';
import '../models/ia_copilot_proxima_acao.dart';
import '../models/ia_copiloto_home.dart';
import '../models/ia_progressao_carga_result.dart';
import '../models/progressao_sugestao.dart';

class IaOperationalException implements Exception {
  final String message;
  final String? reference;
  final int? statusCode;
  final bool retryable;
  final String? codigo;
  final String? upgradePlano;

  const IaOperationalException({
    required this.message,
    this.reference,
    this.statusCode,
    required this.retryable,
    this.codigo,
    this.upgradePlano,
  });

  bool get quotaExhausted => codigo == 'IA_QUOTA_ESGOTADA';
  bool get planUpgradeRequired => codigo == 'IA_PLANO_INSUFICIENTE';
  bool get suggestsUpgrade =>
      upgradePlano != null && upgradePlano!.trim().isNotEmpty;

  SubscriptionPlan? get suggestedUpgradePlan {
    if (!suggestsUpgrade) return null;
    return subscriptionPlanFromApi(upgradePlano);
  }

  factory IaOperationalException.fromDio(DioException error) {
    final status = error.response?.statusCode;
    final payload = error.response?.data;
    final rawMessage =
        payload is Map
            ? (payload['erro'] ?? payload['message'])?.toString()
            : null;
    final codigo = payload is Map ? payload['codigo']?.toString() : null;
    final upgradePlano =
        payload is Map ? payload['upgradePlano']?.toString() : null;
    final fullMessage =
        rawMessage?.trim().isNotEmpty == true
            ? rawMessage!.trim()
            : status == 429
            ? 'Limite de IA atingido agora. Tente novamente em instantes.'
            : status == null
            ? 'Sem conexao com a IA agora.'
            : 'IA temporariamente indisponivel.';
    final reference = _extractReference(fullMessage);
    final message =
        reference == null
            ? fullMessage
            : fullMessage
                .replaceAll(RegExp(r'\s*Ref:\s*[a-zA-Z0-9-]+\.?'), '')
                .trim();
    final retryable =
        !(codigo == 'IA_QUOTA_ESGOTADA' || codigo == 'IA_PLANO_INSUFICIENTE') &&
        (status == null || status == 408 || status == 429 || status >= 500);
    return IaOperationalException(
      message: message,
      reference: reference,
      statusCode: status,
      retryable: retryable,
      codigo: codigo,
      upgradePlano: upgradePlano,
    );
  }

  @override
  String toString() => message;
}

class ExecutarAcaoResponse {
  final String tipoAcao;
  final String status;
  final String mensagem;
  final int exerciciosAjustados;

  const ExecutarAcaoResponse({
    required this.tipoAcao,
    required this.status,
    required this.mensagem,
    required this.exerciciosAjustados,
  });

  bool get ok => status.toUpperCase() == 'OK';

  factory ExecutarAcaoResponse.fromJson(Map<String, dynamic> json) {
    return ExecutarAcaoResponse(
      tipoAcao: json['tipoAcao'] as String? ?? '',
      status: json['status'] as String? ?? '',
      mensagem: json['mensagem'] as String? ?? '',
      exerciciosAjustados: (json['exerciciosAjustados'] as num?)?.toInt() ?? 0,
    );
  }
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
    return _withIaErrorContext(() async {
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
    });
  }

  Future<String> gerarDieta(
    int alunoId, {
    String? objetivo,
    int? pesoKg,
    int? alturaCm,
    String? restricoes,
    int? caloriasAlvo,
  }) async {
    return _withIaErrorContext(() async {
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
    });
  }

  Future<String> chat(String mensagem, {int? alunoId}) async {
    return _withIaErrorContext(() async {
      final r = await _dio.post(
        '/api/ia/chat',
        options: _iaOpts,
        data: {'mensagem': mensagem, if (alunoId != null) 'alunoId': alunoId},
      );
      return r.data['resposta'] as String;
    });
  }

  Future<IaProgressaoCargaResult> progressaoCarga(
    int alunoId, {
    String? objetivo,
    String? historicoTreinos,
  }) async {
    return _withIaErrorContext(() async {
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
      return IaProgressaoCargaResult.fromApi(
        Map<String, dynamic>.from(r.data as Map),
      );
    });
  }

  // ── Copiloto ──────────────────────────────────────────────────────────────

  Future<IaCopilotoHomeBundle> copilotoHome() async {
    return _withIaErrorContext(() async {
      final r = await _dio.get('/api/ia/copiloto/home');
      return IaCopilotoHomeBundle.fromJson(
        Map<String, dynamic>.from(r.data as Map),
      );
    });
  }

  Future<Map<String, dynamic>> resumoSemanal() async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/resumo-semanal',
        options: _iaOpts,
      );
      return r.data as Map<String, dynamic>;
    });
  }

  Future<IaCopilotProximaAcao> proximaAcao(int alunoId) async {
    return _withIaErrorContext(() async {
      final r = await _dio.get(
        '/api/ia/copiloto/proxima-acao/$alunoId',
        options: _iaOpts,
      );
      return IaCopilotProximaAcao.fromJson(
        Map<String, dynamic>.from(r.data as Map),
      );
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

  Future<List<IaCopilotInsight>> insights({
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
          .asMap()
          .entries
          .map(
            (e) => IaCopilotInsight.fromJson(
              Map<String, dynamic>.from(e.value as Map),
              index: e.key,
            ),
          )
          .toList();
    });
  }

  Future<IaCopilotProximaAcao> salvarAcaoCopiloto({
    required int alunoId,
    required String acao,
    String? motivo,
    String? modo,
    String? source,
    String? recommendationId,
    bool createdFromInsight = true,
  }) async {
    return _withIaErrorContext(() async {
      final r = await _dio.post(
        '/api/ia/copiloto/acoes',
        data: {
          'alunoId': alunoId,
          'acao': acao,
          if (motivo != null && motivo.isNotEmpty) 'motivo': motivo,
          if (modo != null && modo.isNotEmpty) 'modo': modo,
          if (source != null && source.isNotEmpty) 'source': source,
          if (recommendationId != null && recommendationId.isNotEmpty)
            'recommendationId': recommendationId,
          'createdFromInsight': createdFromInsight,
        },
      );
      return IaCopilotProximaAcao.fromJson(
        Map<String, dynamic>.from(r.data as Map),
      );
    });
  }

  Future<ExecutarAcaoResponse> executarAcaoCopiloto({
    required int alunoId,
    required String tipoAcao,
    String? parametros,
  }) async {
    return _withIaErrorContext(() async {
      final r = await _dio.post(
        '/api/ia/copiloto/acao/executar',
        options: _iaOpts,
        data: {
          'alunoId': alunoId,
          'tipoAcao': tipoAcao,
          if (parametros != null && parametros.isNotEmpty)
            'parametros': parametros,
        },
      );
      return ExecutarAcaoResponse.fromJson(
        Map<String, dynamic>.from(r.data as Map),
      );
    });
  }

  // ── Progressão sugestões ──────────────────────────────────────────────────

  Future<List<ProgressaoSugestao>> sugestoesProgressao({
    int? alunoId,
    int limit = 50,
  }) async {
    final r = await _dio.get(
      '/api/ia/progressao/sugestoes',
      queryParameters: {
        if (alunoId != null) 'alunoId': alunoId,
        'limit': limit,
      },
    );
    return (r.data as List)
        .map(
          (row) =>
              ProgressaoSugestao.fromApi(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  Future<ProgressaoAceitarResponse> aceitarSugestao(int id) async {
    final r = await _dio.post('/api/ia/progressao/sugestoes/$id/aceitar');
    final data = r.data;
    if (data is Map) {
      return ProgressaoAceitarResponse.fromApi(Map<String, dynamic>.from(data));
    }
    return const ProgressaoAceitarResponse(
      cargaAplicada: true,
      mensagem: 'Sugestão aceita.',
    );
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
