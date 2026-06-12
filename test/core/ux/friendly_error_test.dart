import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/utils/friendly_error.dart';
import 'package:focux_app/core/ux/focux_feedback.dart';

void main() {
  test('uses default fallback for opaque errors', () {
    expect(
      friendlyError(Exception('DioException [bad] internal')),
      FocuxFeedback.defaultFallback,
    );
  });

  test('maps common HTTP status codes to PT-BR messages', () {
    DioException err(int code) => DioException(
          requestOptions: RequestOptions(path: '/test'),
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: code,
          ),
        );

    expect(friendlyError(err(401)), contains('Sessão'));
    expect(friendlyError(err(403)), contains('permissão'));
    expect(friendlyError(err(404)), contains('encontrado'));
    expect(friendlyError(err(429)), contains('tentativas'));
    expect(friendlyError(err(500)), contains('servidor'));
  });

  test('prefers server message when present', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 400,
        data: {'message': 'Plano já ativo para este aluno.'},
      ),
    );
    expect(friendlyError(err), 'Plano já ativo para este aluno.');
  });

  test('maps timeout to connectivity message', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/test'),
      type: DioExceptionType.connectionTimeout,
    );
    expect(friendlyError(err), contains('internet'));
  });
}
