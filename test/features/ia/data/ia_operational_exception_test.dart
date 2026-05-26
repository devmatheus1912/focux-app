import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/data/ia_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';

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
    // Ref must be stripped from message so UI can render it exactly once.
    expect(mapped.message, isNot(contains('Ref:')));
    expect(mapped.message, isNot(contains('abc-123')));
  });

  test('IaOperationalException maps IA quota exhausted with upgrade plan', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/api/ia/copiloto/insights'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/ia/copiloto/insights'),
        statusCode: 403,
        data: {
          'erro': 'Cota mensal de IA esgotada (120 requisicoes/mes). Faca upgrade para ENTERPRISE.',
          'codigo': 'IA_QUOTA_ESGOTADA',
          'upgradePlano': 'ENTERPRISE',
        },
      ),
    );

    final mapped = IaOperationalException.fromDio(error);

    expect(mapped.quotaExhausted, isTrue);
    expect(mapped.suggestsUpgrade, isTrue);
    expect(mapped.retryable, isFalse);
    expect(mapped.suggestedUpgradePlan?.apiName, 'ENTERPRISE');
  });
}
