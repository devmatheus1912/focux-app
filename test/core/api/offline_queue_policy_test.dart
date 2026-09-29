import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_queue_policy.dart';

QueuedRequest _req({String method = 'POST', int attempts = 0}) =>
    QueuedRequest(path: '/api/treinos/1', method: method, attempts: attempts);

DioException _status(int code) {
  final options = RequestOptions(path: '/api/treinos/1');
  return DioException.badResponse(
    statusCode: code,
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: code),
  );
}

DioException _type(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/api/treinos/1'),
  type: type,
);

void main() {
  test('sucesso sai da fila', () {
    expect(decideReplayOutcome(_req(), null), ReplayOutcome.done);
  });

  test('sem chegar ao servidor segura sem gastar tentativa', () {
    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
    ]) {
      expect(
        decideReplayOutcome(_req(attempts: 7), _type(type)),
        ReplayOutcome.hold,
      );
    }
  });

  test('timeout de envio/resposta gasta tentativa até descartar', () {
    for (final type in [
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      expect(
        decideReplayOutcome(_req(attempts: 6), _type(type)),
        ReplayOutcome.retryLater,
      );
      expect(
        decideReplayOutcome(_req(attempts: 7), _type(type)),
        ReplayOutcome.drop,
      );
    }
  });

  test('DELETE com 404 já está feito; outros métodos descartam', () {
    expect(
      decideReplayOutcome(_req(method: 'DELETE'), _status(404)),
      ReplayOutcome.done,
    );
    expect(
      decideReplayOutcome(_req(method: 'PUT'), _status(404)),
      ReplayOutcome.drop,
    );
  });

  test('401 sem logout segura sem gastar tentativa', () {
    expect(
      decideReplayOutcome(_req(attempts: 7), _status(401)),
      ReplayOutcome.hold,
    );
  });

  test('5xx retenta, 4xx permanente descarta', () {
    expect(decideReplayOutcome(_req(), _status(503)), ReplayOutcome.retryLater);
    expect(decideReplayOutcome(_req(), _status(422)), ReplayOutcome.drop);
  });

  test('idade máxima: 7 dias', () {
    final now = DateTime(2026, 9, 28).millisecondsSinceEpoch;
    QueuedRequest aged(Duration age) => QueuedRequest(
      path: '/p',
      method: 'POST',
      enqueuedAtMillis: now - age.inMilliseconds,
    );

    expect(isQueuedRequestExpired(aged(const Duration(days: 6)), now), isFalse);
    expect(isQueuedRequestExpired(aged(const Duration(days: 8)), now), isTrue);
  });

  test('JSON antigo sem enqueuedAtMillis carrega e conta a partir de agora', () {
    final before = DateTime.now().millisecondsSinceEpoch;
    final req = QueuedRequest.fromJson({
      'path': '/api/treinos/1',
      'method': 'POST',
      'attempts': 2,
      'nextRetryAtMillis': 0,
    });

    expect(req.attempts, 2);
    expect(req.enqueuedAtMillis, greaterThanOrEqualTo(before));
    expect(req.toJson()['enqueuedAtMillis'], req.enqueuedAtMillis);
  });

  test('retry preserva a idade original', () {
    final req = QueuedRequest(path: '/p', method: 'POST', enqueuedAtMillis: 42);
    expect(req.withRetry().enqueuedAtMillis, 42);
  });
}
