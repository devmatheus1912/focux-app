import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/api_transport_circuit.dart';

DioException _erro(String method, {int? status, DioExceptionType? type}) {
  final req = RequestOptions(path: '/api/alunos', method: method);
  return DioException(
    requestOptions: req,
    response: status == null ? null : Response(requestOptions: req, statusCode: status),
    type: type ?? DioExceptionType.badResponse,
  );
}

void main() {
  setUp(ApiTransportCircuit.resetForTest);

  test('5xx repete só em GET', () {
    expect(ApiClient.shouldRetryForTest(_erro('GET', status: 502)), isTrue);
    expect(ApiClient.shouldRetryForTest(_erro('POST', status: 502)), isFalse);
  });

  test('mutação repete só se nem conectou', () {
    expect(
      ApiClient.shouldRetryForTest(
        _erro('POST', type: DioExceptionType.connectionTimeout),
      ),
      isTrue,
    );
    expect(
      ApiClient.shouldRetryForTest(
        _erro('POST', type: DioExceptionType.receiveTimeout),
      ),
      isFalse,
    );
  });

  test('429 nunca repete e circuito aberto corta retry', () {
    expect(ApiClient.shouldRetryForTest(_erro('GET', status: 429)), isFalse);
    for (var i = 0; i < ApiTransportCircuit.tripAfterFailures; i++) {
      ApiTransportCircuit.recordTransportFailure();
    }
    expect(ApiClient.shouldRetryForTest(_erro('GET', status: 502)), isFalse);
  });
}
