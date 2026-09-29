import 'package:dio/dio.dart';

/// Respostas de erro que a fila aceita antes de desistir de uma mutação.
const kOfflineQueueMaxAttempts = 8;

/// Mutação parada na fila há mais que isto é descartada com aviso: reenviar
/// uma edição de semanas atrás sobrescreveria o que mudou desde então.
const kOfflineQueueMaxAge = Duration(days: 7);

/// 4xx que ainda valem nova tentativa. `409` entra porque o backend responde
/// isso enquanto a *primeira* requisição com a mesma `Idempotency-Key` está
/// em voo — a tentativa seguinte recebe o replay da resposta original.
const _retryableClientStatuses = {408, 409, 425, 429};

/// Modelo de uma request mutativa enfileirada para retry quando o app
/// estiver offline. Carrega contagem de tentativas e {@code nextRetryAt}
/// para implementar backoff exponencial sem ressubmeter em loop apertado.
class QueuedRequest {
  final String path;
  final String method;
  final dynamic data;
  final Map<String, dynamic>? queryParameters;
  final String? idempotencyKey;
  final int attempts;
  final int nextRetryAtMillis;
  final int enqueuedAtMillis;

  QueuedRequest({
    required this.path,
    required this.method,
    this.data,
    this.queryParameters,
    this.idempotencyKey,
    this.attempts = 0,
    this.nextRetryAtMillis = 0,
    int? enqueuedAtMillis,
  }) : enqueuedAtMillis =
           enqueuedAtMillis ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
    'path': path,
    'method': method,
    'data': data,
    'queryParameters': queryParameters,
    'idempotencyKey': idempotencyKey,
    'attempts': attempts,
    'nextRetryAtMillis': nextRetryAtMillis,
    'enqueuedAtMillis': enqueuedAtMillis,
  };

  /// Item gravado antes de `enqueuedAtMillis` existir conta a idade a partir
  /// de agora; a fila regrava o campo na próxima rodada.
  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    path: json['path'] as String,
    method: json['method'] as String,
    data: json['data'],
    queryParameters: (json['queryParameters'] as Map?)?.cast<String, dynamic>(),
    idempotencyKey: json['idempotencyKey'] as String?,
    attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    nextRetryAtMillis: (json['nextRetryAtMillis'] as num?)?.toInt() ?? 0,
    enqueuedAtMillis: (json['enqueuedAtMillis'] as num?)?.toInt(),
  );

  QueuedRequest withRetry() {
    final next = attempts + 1;
    return QueuedRequest(
      path: path,
      method: method,
      data: data,
      queryParameters: queryParameters,
      idempotencyKey: idempotencyKey,
      attempts: next,
      nextRetryAtMillis: DateTime.now().millisecondsSinceEpoch + _backoff(next),
      enqueuedAtMillis: enqueuedAtMillis,
    );
  }

  bool get isReadyToRetry =>
      DateTime.now().millisecondsSinceEpoch >= nextRetryAtMillis;

  static int _backoff(int attempt) {
    // 5s, 15s, 45s, 2m15s, 6m45s, 20m, então cap de 1h.
    if (attempt <= 0) return 0;
    const base = 5 * 1000;
    final exp = base * pow3(attempt - 1);
    return exp > 3600 * 1000 ? 3600 * 1000 : exp;
  }

  static int pow3(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 3;
    }
    return r;
  }
}

/// Mutação que a fila desistiu de reenviar, guardada para a UI poder contar a
/// verdade depois de já ter respondido `202 queued` ao usuário.
class DroppedMutation {
  final String path;
  final String method;
  final int? statusCode;
  final int droppedAtMillis;

  const DroppedMutation({
    required this.path,
    required this.method,
    this.statusCode,
    required this.droppedAtMillis,
  });

  factory DroppedMutation.of(QueuedRequest req, {Object? error}) =>
      DroppedMutation(
        path: req.path,
        method: req.method,
        statusCode: error is DioException ? error.response?.statusCode : null,
        droppedAtMillis: DateTime.now().millisecondsSinceEpoch,
      );

  Map<String, dynamic> toJson() => {
    'path': path,
    'method': method,
    'statusCode': statusCode,
    'droppedAtMillis': droppedAtMillis,
  };

  factory DroppedMutation.fromJson(Map<String, dynamic> json) =>
      DroppedMutation(
        path: json['path'] as String? ?? '',
        method: json['method'] as String? ?? '',
        statusCode: (json['statusCode'] as num?)?.toInt(),
        droppedAtMillis: (json['droppedAtMillis'] as num?)?.toInt() ?? 0,
      );
}

/// O que a fila faz com um item depois de tentar reenviá-lo.
enum ReplayOutcome {
  /// Saiu da fila: enviado, ou o estado desejado já vale.
  done,

  /// Fica como está, sem gastar tentativa, e segura os seguintes.
  hold,

  /// Gasta uma tentativa, entra no backoff e segura os seguintes.
  retryLater,

  /// Sai da fila com aviso ao usuário.
  drop,
}

bool isQueuedRequestExpired(QueuedRequest req, int nowMillis) =>
    nowMillis - req.enqueuedAtMillis > kOfflineQueueMaxAge.inMilliseconds;

ReplayOutcome decideReplayOutcome(QueuedRequest req, Object? error) {
  if (error == null) return ReplayOutcome.done;
  if (error is DioException) {
    final status = error.response?.statusCode;
    // DELETE reenviado depois que o original passou, ou recurso que já
    // sumiu: o que o usuário pediu já é verdade.
    if (status == 404 && req.method.toUpperCase() == 'DELETE') {
      return ReplayOutcome.done;
    }
    // Não chegou ao servidor: nada a aprender sobre a mutação. Timeout de
    // envio/resposta pode ter chegado e conta tentativa (Idempotency-Key
    // protege o reenvio).
    if (status == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout)) {
      return ReplayOutcome.hold;
    }
  }
  // Erro que nunca vai passar (validação, gate de plano, recurso que sumiu)
  // não ganha nova tentativa: reenviar 8 vezes só atrasa o aviso ao usuário,
  // que já recebeu `202 queued` como se tivesse dado certo.
  if (_isRetryable(error) && req.attempts + 1 < kOfflineQueueMaxAttempts) {
    return ReplayOutcome.retryLater;
  }
  return ReplayOutcome.drop;
}

/// Na dúvida, retenta: só descarta o que dá para provar que é permanente.
bool _isRetryable(Object error) {
  if (error is! DioException) return true;
  final status = error.response?.statusCode;
  if (status == null) return true;
  if (status >= 500) return true;
  if (status >= 400) return _retryableClientStatuses.contains(status);
  return true;
}
