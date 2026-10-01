import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/notificacoes/data/notificacoes_repository.dart';

class _Adapter implements HttpClientAdapter {
  final List<String> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chave = '${options.method} ${options.path}';
    chamadas.add(chave);
    if (chave == 'DELETE /api/notificacoes/lidas') {
      return ResponseBody.fromString(
        jsonEncode({'removidas': 3}),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('', 204);
  }

  @override
  void close({bool force = false}) {}
}

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.dio);

  @override
  final Dio dio;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Adapter adapter;
  late NotificacoesRepository repo;

  setUp(() {
    adapter = _Adapter();
    final dio = Dio()..httpClientAdapter = adapter;
    repo = NotificacoesRepository(_FakeApiClient(dio));
  });

  test('apagar chama DELETE no id', () async {
    await repo.apagar(42);
    expect(adapter.chamadas, ['DELETE /api/notificacoes/42']);
  });

  test('apagarLidas devolve quantas saíram', () async {
    expect(await repo.apagarLidas(), 3);
    expect(adapter.chamadas, ['DELETE /api/notificacoes/lidas']);
  });
}
