import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/data/ia_repository.dart';

void main() {
  test('IaOperationalException extracts backend reference and retryable status', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/ia/copiloto/insights'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/ia/copiloto/insights'),
        statusCode: 503,
        data: {
          'erro': 'IA temporariamente indisponivel. Tente novamente. Ref: abc-123',
        },
      ),
    );

    final mapped = IaOperationalException.fromDio(error);

    expect(mapped.retryable, isTrue);
    expect(mapped.statusCode, 503);
    expect(mapped.reference, 'abc-123');
    expect(mapped.message, contains('IA temporariamente'));
  });
}
