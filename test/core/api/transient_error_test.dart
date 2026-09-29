import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/transient_error.dart';

DioException _semResposta(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

DioException _status(int code) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: code),
  );
}

void main() {
  test('erro de conexão: sem resposta por rede ou timeout', () {
    expect(isConnectionError(_semResposta(DioExceptionType.connectionError)), isTrue);
    expect(isConnectionError(_semResposta(DioExceptionType.connectionTimeout)), isTrue);
    expect(isConnectionError(_semResposta(DioExceptionType.sendTimeout)), isTrue);
    expect(isConnectionError(_semResposta(DioExceptionType.receiveTimeout)), isTrue);
    expect(isConnectionError(_semResposta(DioExceptionType.cancel)), isFalse);
    expect(isConnectionError(_status(400)), isFalse);
    expect(isConnectionError(_status(500)), isFalse);
    expect(isConnectionError(StateError('x')), isFalse);
  });

  test('transitório: conexão, 5xx, 401, 408 e 429; 4xx definitivo não', () {
    expect(isTransientApiError(_semResposta(DioExceptionType.connectionError)), isTrue);
    expect(isTransientApiError(_status(503)), isTrue);
    expect(isTransientApiError(_status(401)), isTrue);
    expect(isTransientApiError(_status(408)), isTrue);
    expect(isTransientApiError(_status(429)), isTrue);
    expect(isTransientApiError(_status(400)), isFalse);
    expect(isTransientApiError(_status(404)), isFalse);
    expect(isTransientApiError(StateError('x')), isFalse);
  });
}
