import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/utils/iap_completion_policy.dart';

DioException _http(int status) {
  final req = RequestOptions(path: '/api/iap/verify');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: status),
  );
}

DioException _semResposta(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/api/iap/verify'),
  type: type,
);

bool _ios(Object erro) =>
    iapShouldCompleteAfterVerifyFailure(error: erro, isAndroid: false);

void main() {
  test('iOS: falha transitória não conclui', () {
    expect(_ios(_semResposta(DioExceptionType.connectionError)), isFalse);
    expect(_ios(_semResposta(DioExceptionType.connectionTimeout)), isFalse);
    expect(_ios(_semResposta(DioExceptionType.receiveTimeout)), isFalse);
    expect(_ios(_http(500)), isFalse);
    expect(_ios(_http(503)), isFalse);
    expect(_ios(_http(429)), isFalse);
  });

  test('iOS: qualquer falha sem resposta que não foi cancelada não conclui', () {
    expect(_ios(_semResposta(DioExceptionType.unknown)), isFalse);
    expect(_ios(_semResposta(DioExceptionType.badCertificate)), isFalse);
    expect(_ios(_semResposta(DioExceptionType.cancel)), isTrue);
  });

  test('falha transitória do verify é a mesma regra da conclusão no iOS', () {
    expect(iapVerifyFailureIsTransient(_semResposta(DioExceptionType.unknown)), isTrue);
    expect(iapVerifyFailureIsTransient(_http(503)), isTrue);
    expect(iapVerifyFailureIsTransient(_http(403)), isFalse);
    expect(iapVerifyFailureIsTransient(StateError('payload')), isFalse);
  });

  test('iOS: recusa definitiva conclui', () {
    expect(_ios(_http(400)), isTrue);
    expect(_ios(_http(403)), isTrue);
    expect(_ios(_http(404)), isTrue);
    expect(_ios(_http(422)), isTrue);
    expect(_ios(StateError('payload')), isTrue);
  });

  test('Android: conclui sempre', () {
    for (final erro in <Object>[
      _semResposta(DioExceptionType.connectionError),
      _http(503),
      _http(403),
    ]) {
      expect(
        iapShouldCompleteAfterVerifyFailure(error: erro, isAndroid: true),
        isTrue,
      );
    }
  });
}
