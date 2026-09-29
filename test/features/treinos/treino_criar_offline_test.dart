import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/offline_queued_ack.dart';
import 'package:focux_app/core/api/offline_sync_service.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

class _CriadoAdapter implements HttpClientAdapter {
  final keys = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    keys.add(options.headers['Idempotency-Key'] as String?);
    return ResponseBody.fromString(
      '{"id": 7, "nome": "Treino A", "exercicios": []}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TreinoRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetIdempotencyScopes();
    final client = ApiClient()..dio.httpClientAdapter = _OfflineAdapter();
    repository = TreinoRepository(client);
  });

  test('sem aluno: criar offline entra na fila', () async {
    await expectLater(
      repository.criar('Treino A', null, null, null, formNonce: 'f'),
      throwsA(isA<OfflineQueuedException>()),
    );
    expect(await OfflineSyncService.getPendingCount(), 1);
  });

  test('para atribuir a aluno: offline é erro de conexão, fora da fila',
      () async {
    await expectLater(
      repository.criar(
        'Treino A',
        null,
        null,
        null,
        formNonce: 'f',
        offlineQueue: false,
      ),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(await OfflineSyncService.getPendingCount(), 0);
  });

  test('dois envios do mesmo formulário levam a mesma chave', () async {
    final adapter = _CriadoAdapter();
    final repo = TreinoRepository(ApiClient()..dio.httpClientAdapter = adapter);

    Future<Treino> enviar(String nonce) => repo.criar(
      'Treino A',
      null,
      null,
      null,
      offlineQueue: false,
      formNonce: nonce,
    );

    await enviar('form-1');
    await enviar('form-1');
    await enviar('form-2');

    expect(adapter.keys, everyElement(isNotNull));
    expect(adapter.keys.toSet(), hasLength(2));
    expect(adapter.keys[0], adapter.keys[1]);
    expect(adapter.keys[2], isNot(adapter.keys[0]));
  });
}
