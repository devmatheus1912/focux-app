import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_transport_circuit.dart';
import 'package:focux_app/core/auth/session_refresh_coordinator.dart';

void main() {
  setUp(() {
    ApiTransportCircuit.resetForTest();
    SessionRefreshCoordinator.resetForTest();
  });

  test('ApiTransportCircuit abre após N falhas e fecha no sucesso', () {
    expect(ApiTransportCircuit.isOpen, isFalse);
    for (var i = 0; i < ApiTransportCircuit.tripAfterFailures; i++) {
      ApiTransportCircuit.recordTransportFailure();
    }
    expect(ApiTransportCircuit.isOpen, isTrue);
    ApiTransportCircuit.recordSuccess();
    expect(ApiTransportCircuit.isOpen, isFalse);
  });

  test('SessionRefreshCoordinator.shouldRetryRequest', () {
    expect(
      SessionRefreshCoordinator.shouldRetryRequest(
        SessionRefreshOutcome.refreshed,
      ),
      isTrue,
    );
    expect(
      SessionRefreshCoordinator.shouldRetryRequest(
        SessionRefreshOutcome.fresh,
      ),
      isTrue,
    );
    expect(
      SessionRefreshCoordinator.shouldRetryRequest(
        SessionRefreshOutcome.failedRetryable,
      ),
      isFalse,
    );
    expect(
      SessionRefreshCoordinator.shouldRetryRequest(
        SessionRefreshOutcome.failedFatal,
      ),
      isFalse,
    );
  });
}
