import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';

DioException _err({
  int? status,
  String path = '/api/dashboard/home',
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path, method: 'GET'),
    response:
        status == null
            ? null
            : Response(
              requestOptions: RequestOptions(path: path),
              statusCode: status,
            ),
    type: type,
  );
}

void main() {
  setUp(ApiClient.resetErrorReportGateForTest);

  test('não reporta 401/403/429 nem 4xx de cliente', () {
    expect(ApiClient.tryReserveErrorReportSlotForTest(_err(status: 401)), isFalse);
    expect(ApiClient.tryReserveErrorReportSlotForTest(_err(status: 403)), isFalse);
    expect(ApiClient.tryReserveErrorReportSlotForTest(_err(status: 429)), isFalse);
    expect(ApiClient.tryReserveErrorReportSlotForTest(_err(status: 404)), isFalse);
    expect(ApiClient.tryReserveErrorReportSlotForTest(_err(status: 422)), isFalse);
  });

  test('não reporta o próprio endpoint de análise', () {
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(status: 500, path: '/api/suporte/analisar-erro'),
      ),
      isFalse,
    );
  });

  test('aceita 5xx e rede, com teto e dedupe por fingerprint', () {
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(_err(status: 500)),
      isTrue,
    );
    // Same fingerprint → blocked.
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(_err(status: 500)),
      isFalse,
    );

    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(status: 502, path: '/api/treinos/1'),
      ),
      isTrue,
    );
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(
          status: null,
          type: DioExceptionType.connectionError,
          path: '/api/alunos',
        ),
      ),
      isTrue,
    );
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(status: 503, path: '/api/agenda'),
      ),
      isTrue,
    );
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(status: 504, path: '/api/relatorios'),
      ),
      isTrue,
    );
    // 6th distinct → window full (max 5).
    expect(
      ApiClient.tryReserveErrorReportSlotForTest(
        _err(status: 500, path: '/api/ia/chat'),
      ),
      isFalse,
    );
  });

  test('contrato: não retenta 429 e gate existe no ApiClient', () {
    final src = File('lib/core/api/api_client.dart').readAsStringSync();
    expect(src, contains('_tryReserveErrorReportSlot'));
    expect(src, contains('_errorReportMaxPerWindow = 5'));
    expect(src, contains('Never auto-retry 429'));
    expect(
      src,
      isNot(contains('status == 408 || status == 429 || status >= 500')),
    );
    expect(src, contains('status == 408 || status >= 500'));
  });
}
