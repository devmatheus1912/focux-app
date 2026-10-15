import 'dart:convert';

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

  test('replay após refresh só com o Bearer da mesma conta', () {
    String jwt(String sub, int personalId) {
      final payload = base64Url
          .encode(utf8.encode('{"sub":"$sub","personal_id":$personalId}'))
          .replaceAll('=', '');
      return 'h.$payload.s';
    }

    final a1 = jwt('a@focux.test', 1);
    final a2 = jwt('a@focux.test', 1);
    final b = jwt('b@focux.test', 2);
    expect(SessionRefreshCoordinator.canReplayAs('Bearer $a1', a2), isTrue);
    expect(SessionRefreshCoordinator.canReplayAs('Bearer $a1', b), isFalse);
    expect(SessionRefreshCoordinator.canReplayAs(null, a2), isFalse);
    expect(SessionRefreshCoordinator.canReplayAs('Bearer lixo', a2), isFalse);
  });

  test('dois 401 ao mesmo tempo dividem um só refresh', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final a = SessionRefreshCoordinator.ensureFreshAccess(force: true);
    final b = SessionRefreshCoordinator.ensureFreshAccess(force: true);
    expect(identical(a, b), isTrue);
    SessionRefreshCoordinator.resetStuckLock();
    expect(await a, await b);
  });
}
