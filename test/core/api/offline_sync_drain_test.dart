import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Path fora de [OfflineSyncService.isSensitivePath].
const _path = '/api/treinos/1/concluir';

class _Adapter implements HttpClientAdapter {
  _Adapter({this.statusCode = 200, this.onFetch});

  final int statusCode;
  final Future<void> Function(RequestOptions options)? onFetch;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    await onFetch?.call(options);
    return ResponseBody.fromString('{}', statusCode);
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _enqueue(String path) => OfflineSyncService.enqueueRequest(
  RequestOptions(path: path, method: 'POST', data: {'ok': true}),
);

/// Zera o backoff gravado para a próxima rodada tentar de novo já.
Future<void> _skipBackoff() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('offline_outbox_queue');
  if (raw == null) return;
  final items = [
    for (final e in jsonDecode(raw) as List)
      {...(e as Map<String, dynamic>), 'nextRetryAtMillis': 0},
  ];
  await prefs.setString('offline_outbox_queue', jsonEncode(items));
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _enqueue(_path);
  });

  test('single-flight: duas drenagens simultâneas enviam o item uma vez', () async {
    final gate = Completer<void>();
    final adapter = _Adapter(onFetch: (_) => gate.future);
    final dio = Dio()..httpClientAdapter = adapter;

    final a = OfflineSyncService.syncPendingRequests(dio);
    final b = OfflineSyncService.syncPendingRequests(dio);
    gate.complete();
    await Future.wait([a, b]);

    expect(adapter.requests, hasLength(1));
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('replay não volta a ser enfileirado pelo cliente', () async {
    final adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;

    await OfflineSyncService.syncPendingRequests(dio);

    final extra = adapter.requests.single.extra;
    expect(extra[OfflineSyncService.noQueueExtra], isTrue);
    expect(extra['fxNoRetry'], isTrue);
  });

  test('ação enfileirada durante a drenagem não se perde', () async {
    final adapter = _Adapter(
      onFetch: (options) async {
        if (options.path == _path) await _enqueue('/api/treinos/2/concluir');
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;

    await OfflineSyncService.syncPendingRequests(dio);

    expect(await OfflineSyncService.getPendingCount(), 1);
  });

  test('logout durante a drenagem não devolve itens à fila', () async {
    final adapter = _Adapter(
      statusCode: 503,
      onFetch: (_) => OfflineSyncService.clearQueue(),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    await OfflineSyncService.syncPendingRequests(dio);

    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('logout durante 4xx não grava nem avisa descarte', () async {
    final avisos = <List<DroppedMutation>>[];
    OfflineSyncService.onMutationsDropped = avisos.add;
    addTearDown(() => OfflineSyncService.onMutationsDropped = null);
    final adapter = _Adapter(
      statusCode: 400,
      onFetch: (_) => OfflineSyncService.clearQueue(),
    );

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = adapter,
    );

    expect(await OfflineSyncService.pendingDropped(), isEmpty);
    expect(avisos, isEmpty);
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('item em backoff segura o item pronto atrás dele', () async {
    SharedPreferences.setMockInitialValues({
      'offline_outbox_queue': jsonEncode([
        QueuedRequest(
          path: _path,
          method: 'POST',
          attempts: 1,
          nextRetryAtMillis:
              DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
        ).toJson(),
        QueuedRequest(path: '/api/treinos/2/concluir', method: 'POST').toJson(),
      ]),
    });
    final adapter = _Adapter();

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = adapter,
    );

    expect(adapter.requests, isEmpty);
    expect(await OfflineSyncService.getPendingCount(), 2);
  });

  test('falha retentável no primeiro item não envia os seguintes', () async {
    await _enqueue('/api/treinos/2/concluir');
    final adapter = _Adapter(statusCode: 503);

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = adapter,
    );

    expect(adapter.requests.map((r) => r.path), [_path]);
    expect(await OfflineSyncService.getPendingCount(), 2);
  });

  test('falha de transporte não gasta tentativa', () async {
    final adapter = _Adapter(
      onFetch: (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    for (var i = 0; i < 10; i++) {
      await OfflineSyncService.syncPendingRequests(dio);
    }

    expect(adapter.requests, hasLength(10));
    expect(await OfflineSyncService.getPendingCount(), 1);
    expect(await OfflineSyncService.pendingDropped(), isEmpty);
  });

  test('receiveTimeout 8 vezes descarta com registro', () async {
    final adapter = _Adapter(
      onFetch: (options) async => throw DioException.receiveTimeout(
        timeout: const Duration(seconds: 1),
        requestOptions: options,
      ),
    );
    final dio = Dio()..httpClientAdapter = adapter;

    for (var i = 0; i < 8; i++) {
      await _skipBackoff();
      await OfflineSyncService.syncPendingRequests(dio);
    }

    expect(adapter.requests, hasLength(8));
    expect(await OfflineSyncService.getPendingCount(), 0);
    expect(await OfflineSyncService.pendingDropped(), hasLength(1));
  });

  test('item com mais de 7 dias sai sem reenvio e com aviso', () async {
    SharedPreferences.setMockInitialValues({
      'offline_outbox_queue': jsonEncode([
        QueuedRequest(
          path: _path,
          method: 'POST',
          enqueuedAtMillis:
              DateTime.now()
                  .subtract(const Duration(days: 8))
                  .millisecondsSinceEpoch,
        ).toJson(),
      ]),
    });
    final avisos = <List<DroppedMutation>>[];
    OfflineSyncService.onMutationsDropped = avisos.add;
    addTearDown(() => OfflineSyncService.onMutationsDropped = null);
    final adapter = _Adapter();

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = adapter,
    );

    expect(adapter.requests, isEmpty);
    expect(await OfflineSyncService.getPendingCount(), 0);
    expect(await OfflineSyncService.pendingDropped(), hasLength(1));
    expect(avisos, hasLength(1));
  });

  test('fila gravada sem enqueuedAtMillis continua carregando', () async {
    SharedPreferences.setMockInitialValues({
      'offline_outbox_queue': jsonEncode([
        {'path': _path, 'method': 'POST', 'attempts': 0, 'nextRetryAtMillis': 0},
      ]),
    });
    final adapter = _Adapter(
      onFetch: (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = adapter,
    );

    expect(adapter.requests, hasLength(1));
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString('offline_outbox_queue')!) as List;
    expect((saved.single as Map)['enqueuedAtMillis'], isA<int>());
  });

  test('DELETE com 404 no reenvio conta como feito, sem aviso', () async {
    SharedPreferences.setMockInitialValues({});
    await OfflineSyncService.enqueueRequest(
      RequestOptions(path: '/api/treinos/9', method: 'DELETE'),
    );
    final avisos = <List<DroppedMutation>>[];
    OfflineSyncService.onMutationsDropped = avisos.add;
    addTearDown(() => OfflineSyncService.onMutationsDropped = null);

    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = _Adapter(statusCode: 404),
    );

    expect(await OfflineSyncService.getPendingCount(), 0);
    expect(await OfflineSyncService.pendingDropped(), isEmpty);
    expect(avisos, isEmpty);
  });

  test('fila avisa quando muda', () async {
    final events = <void>[];
    final sub = OfflineSyncService.changes.listen(events.add);
    addTearDown(sub.cancel);

    await _enqueue('/api/treinos/3/concluir');
    await OfflineSyncService.syncPendingRequests(
      Dio()..httpClientAdapter = _Adapter(),
    );
    await pumpEventQueue();

    expect(events.length, greaterThanOrEqualTo(2));
  });
}
