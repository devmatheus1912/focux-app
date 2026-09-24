import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda a `Idempotency-Key` que saiu em cada request, que e a unica coisa
/// que o servidor usa para decidir se duas submissoes sao a mesma operacao.
class _KeyCaptureAdapter implements HttpClientAdapter {
  final List<String?> keys = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    keys.add(options.headers['Idempotency-Key'] as String?);
    return ResponseBody.fromString(
      jsonEncode({'ok': true}),
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

  late _KeyCaptureAdapter adapter;
  late ApiClient client;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    // O construtor do ApiClient dispara o dreno da fila offline.
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetIdempotencyScopes();
    adapter = _KeyCaptureAdapter();
    client = ApiClient();
    client.dio.httpClientAdapter = adapter;
  });

  test('mesmo escopo reaproveita a chave: dois toques, uma mutacao', () async {
    final options = ApiClient.idempotent('mensalidade-pagar-7');
    await client.dio.put('/api/financeiro/mensalidades/7/pagar', options: options);
    await client.dio.put('/api/financeiro/mensalidades/7/pagar', options: options);

    expect(adapter.keys, hasLength(2));
    expect(adapter.keys[0], isNotNull);
    expect(adapter.keys[0], adapter.keys[1]);
  });

  test('mesmo escopo com payload diferente ganha chave nova', () async {
    final options = ApiClient.idempotent('upsell-patch-3');
    await client.dio.patch('/api/upsell/ofertas/3', data: {'titulo': 'A'}, options: options);
    await client.dio.patch('/api/upsell/ofertas/3', data: {'titulo': 'B'}, options: options);
    await client.dio.patch('/api/upsell/ofertas/3', data: {'titulo': 'B'}, options: options);

    expect(adapter.keys[0], isNot(adapter.keys[1]));
    expect(adapter.keys[1], adapter.keys[2]);
  });

  test('fingerprint ignora ordem das chaves do payload', () {
    expect(
      ApiClient.payloadFingerprint({'a': 1, 'b': [2, 3]}),
      ApiClient.payloadFingerprint({'b': [2, 3], 'a': 1}),
    );
  });

  test('escopos diferentes nao colidem', () async {
    await client.dio.put(
      '/api/financeiro/mensalidades/7/pagar',
      options: ApiClient.idempotent('mensalidade-pagar-7'),
    );
    await client.dio.put(
      '/api/financeiro/mensalidades/8/pagar',
      options: ApiClient.idempotent('mensalidade-pagar-8'),
    );

    expect(adapter.keys[0], isNot(adapter.keys[1]));
  });

  test('sem escopo cada tentativa ganha chave nova', () async {
    await client.dio.put('/api/financeiro/mensalidades/7/pagar');
    await client.dio.put('/api/financeiro/mensalidades/7/pagar');

    expect(adapter.keys[0], isNotNull);
    expect(adapter.keys[0], isNot(adapter.keys[1]));
  });

  test('escopo declarado pelo chamador nao apaga header explicito', () async {
    await client.dio.put(
      '/api/financeiro/mensalidades/7/pagar',
      options: Options(
        headers: {'Idempotency-Key': 'chave-do-chamador'},
        extra: const {'fxIdempotencyScope': 'mensalidade-pagar-7'},
      ),
    );

    expect(adapter.keys.single, 'chave-do-chamador');
  });

  test('GET nao recebe chave de idempotencia', () async {
    await client.dio.get(
      '/api/financeiro/home',
      options: ApiClient.idempotent('irrelevante'),
    );

    expect(adapter.keys.single, isNull);
  });

  test('idempotent preserva os extras que o chamador passou', () {
    final options = ApiClient.idempotent(
      'mensalidade-pix-3',
      extra: {'fxNoOfflineQueue': true},
    );

    expect(options.extra?['fxNoOfflineQueue'], isTrue);
    expect(options.extra?['fxIdempotencyScope'], 'mensalidade-pix-3');
  });
}
