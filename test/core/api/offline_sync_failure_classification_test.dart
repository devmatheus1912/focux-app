import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Conta chamadas e responde sempre o mesmo status, para separar "quantas
/// tentativas a fila gastou" de "o que ela decidiu fazer com a mutacao".
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.statusCode);

  final int statusCode;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    return ResponseBody.fromString(
      jsonEncode({'mensagem': 'stub'}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Path fora de [OfflineSyncService.isSensitivePath], senao a fila nem enfileira.
const _path = '/api/treinos/1/concluir';

Future<Dio> _seedQueue(int statusCode, {required _StubAdapter adapter}) async {
  SharedPreferences.setMockInitialValues({});
  await OfflineSyncService.enqueueRequest(
    RequestOptions(path: _path, method: 'POST', data: {'ok': true}),
  );
  expect(await OfflineSyncService.getPendingCount(), 1);
  final dio = Dio()..httpClientAdapter = adapter;
  return dio;
}

void main() {
  tearDown(() => OfflineSyncService.onMutationDropped = null);

  test('4xx permanente sai da fila na primeira tentativa', () async {
    final adapter = _StubAdapter(422);
    final dio = await _seedQueue(422, adapter: adapter);

    await OfflineSyncService.syncPendingRequests(dio);

    // O ponto do fix: uma tentativa, nao oito.
    expect(adapter.calls, 1);
    expect(await OfflineSyncService.getPendingCount(), 0);

    final dropped = await OfflineSyncService.pendingDropped();
    expect(dropped, hasLength(1));
    expect(dropped.single.path, _path);
    expect(dropped.single.method, 'POST');
    expect(dropped.single.statusCode, 422);
  });

  test('gate de plano (403) nao vira retry', () async {
    final adapter = _StubAdapter(403);
    final dio = await _seedQueue(403, adapter: adapter);

    await OfflineSyncService.syncPendingRequests(dio);

    expect(adapter.calls, 1);
    expect(await OfflineSyncService.getPendingCount(), 0);
    expect(await OfflineSyncService.pendingDropped(), hasLength(1));
  });

  test('5xx continua na fila para nova tentativa', () async {
    final adapter = _StubAdapter(503);
    final dio = await _seedQueue(503, adapter: adapter);

    await OfflineSyncService.syncPendingRequests(dio);

    expect(adapter.calls, 1);
    expect(await OfflineSyncService.getPendingCount(), 1);
    expect(await OfflineSyncService.pendingDropped(), isEmpty);
  });

  test('409 continua na fila: e replay da chave em voo, nao conflito final',
      () async {
    final adapter = _StubAdapter(409);
    final dio = await _seedQueue(409, adapter: adapter);

    await OfflineSyncService.syncPendingRequests(dio);

    expect(await OfflineSyncService.getPendingCount(), 1);
    expect(await OfflineSyncService.pendingDropped(), isEmpty);
  });

  test('429 continua na fila', () async {
    final adapter = _StubAdapter(429);
    final dio = await _seedQueue(429, adapter: adapter);

    await OfflineSyncService.syncPendingRequests(dio);

    expect(await OfflineSyncService.getPendingCount(), 1);
    expect(await OfflineSyncService.pendingDropped(), isEmpty);
  });

  test('descarte notifica quem estiver ouvindo', () async {
    final adapter = _StubAdapter(400);
    final dio = await _seedQueue(400, adapter: adapter);

    final avisos = <DroppedMutation>[];
    OfflineSyncService.onMutationDropped = avisos.add;

    await OfflineSyncService.syncPendingRequests(dio);

    expect(avisos, hasLength(1));
    expect(avisos.single.statusCode, 400);
  });

  test('invalidacao de sessao leva o registro de descartes', () async {
    final adapter = _StubAdapter(422);
    final dio = await _seedQueue(422, adapter: adapter);
    await OfflineSyncService.syncPendingRequests(dio);
    expect(await OfflineSyncService.pendingDropped(), hasLength(1));

    await OfflineSyncService.clearQueue();

    expect(await OfflineSyncService.pendingDropped(), isEmpty);
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('registro de descartes tem teto', () async {
    SharedPreferences.setMockInitialValues({});
    final adapter = _StubAdapter(422);
    final dio = Dio()..httpClientAdapter = adapter;
    for (var i = 0; i < 25; i++) {
      await OfflineSyncService.enqueueRequest(
        RequestOptions(path: '$_path/$i', method: 'POST'),
      );
    }

    await OfflineSyncService.syncPendingRequests(dio);

    final dropped = await OfflineSyncService.pendingDropped();
    expect(dropped, hasLength(20));
    // Mantem as ultimas, nao as primeiras.
    expect(dropped.last.path, '$_path/24');
  });
}
