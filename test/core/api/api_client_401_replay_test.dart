import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';

void main() {
  test('FormData e upload com fxNoRetry não são reenviados após 401', () {
    final form = RequestOptions(
      path: '/api/uploads',
      data: FormData.fromMap({'file': 'x'}),
    );
    expect(ApiClient.canReplayAfterAuthRefresh(form), isFalse);

    final upload = RequestOptions(path: '/api/uploads');
    ApiClient.applyUploadPolicy(upload);
    expect(ApiClient.canReplayAfterAuthRefresh(upload), isFalse);
  });

  test('JSON comum pode ser reenviado depois do refresh', () {
    final o = RequestOptions(path: '/api/treinos', data: {'ok': true});
    expect(ApiClient.canReplayAfterAuthRefresh(o), isTrue);
  });

  test('falha de replay que não é 401 não derruba a sessão', () {
    final req = RequestOptions(path: '/api/uploads');
    expect(
      ApiClient.shouldInvalidateAfterAuthReplayFailure(
        DioException(
          requestOptions: req,
          type: DioExceptionType.unknown,
          error: StateError('The FormData has already been finalized.'),
        ),
      ),
      isFalse,
    );
    expect(
      ApiClient.shouldInvalidateAfterAuthReplayFailure(
        DioException(
          requestOptions: req,
          response: Response(requestOptions: req, statusCode: 500),
        ),
      ),
      isFalse,
    );
    expect(
      ApiClient.shouldInvalidateAfterAuthReplayFailure(
        StateError('The FormData has already been finalized.'),
      ),
      isFalse,
    );
  });

  test('replay ainda 401 derruba a sessão', () {
    final req = RequestOptions(path: '/api/treinos');
    expect(
      ApiClient.shouldInvalidateAfterAuthReplayFailure(
        DioException(
          requestOptions: req,
          response: Response(requestOptions: req, statusCode: 401),
        ),
      ),
      isTrue,
    );
  });
}
