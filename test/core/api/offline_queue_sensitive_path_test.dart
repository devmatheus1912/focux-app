import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('check-in and finance writes are sensitive — no fake queue ack', () {
    expect(
      OfflineSyncService.isSensitivePath(
        '/api/checkin/12/exercicio/3/series',
      ),
      isTrue,
    );
    expect(
      OfflineSyncService.isSensitivePath(
        '/api/financeiro/mensalidades/9/pagar',
      ),
      isTrue,
    );
    expect(
      OfflineSyncService.isSensitivePath('/api/financeiro/lote/marcar-pago'),
      isTrue,
    );
    expect(
      OfflineSyncService.isSensitivePath('/api/treinos/1/concluir'),
      isFalse,
    );
  });

  test('sensitive POST is not treated as queueable by ApiClient', () {
    expect(
      ApiClient.canQueueOfflineMutationForTest(
        RequestOptions(
          path: '/api/checkin/12/exercicio/3/series',
          method: 'POST',
        ),
      ),
      isFalse,
    );
    expect(
      ApiClient.canQueueOfflineMutationForTest(
        RequestOptions(
          path: '/api/financeiro/lote/marcar-pago',
          method: 'POST',
        ),
      ),
      isFalse,
    );
    expect(
      ApiClient.canQueueOfflineMutationForTest(
        RequestOptions(path: '/api/treinos/1/concluir', method: 'POST'),
      ),
      isTrue,
    );
  });

  test('enqueueRequest refuses sensitive paths and does not persist them',
      () async {
    final queued = await OfflineSyncService.enqueueRequest(
      RequestOptions(
        path: '/api/checkin/12/exercicio/3/series',
        method: 'POST',
        data: {'numero': 1},
      ),
    );
    expect(queued, isFalse);
    expect(await OfflineSyncService.getPendingCount(), 0);

    final paid = await OfflineSyncService.enqueueRequest(
      RequestOptions(
        path: '/api/financeiro/mensalidades/9/pagar',
        method: 'PUT',
      ),
    );
    expect(paid, isFalse);
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('enqueueRequest persists non-sensitive mutations', () async {
    final queued = await OfflineSyncService.enqueueRequest(
      RequestOptions(
        path: '/api/treinos/1/concluir',
        method: 'POST',
        data: {'ok': true},
      ),
    );
    expect(queued, isTrue);
    expect(await OfflineSyncService.getPendingCount(), 1);
  });
}
