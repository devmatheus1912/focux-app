import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/get_dedupe.dart';

class _Adapter implements HttpClientAdapter {
  int chamadas = 0;
  bool falha = false;
  final portao = Completer<void>();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas++;
    await portao.future;
    if (falha) {
      falha = false;
      return ResponseBody.fromString('{}', 500);
    }
    return ResponseBody.fromString(
      jsonEncode({'ok': chamadas}),
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Adapter adapter) {
  final dedupe = GetDedupe();
  return Dio()
    ..httpClientAdapter = adapter
    ..interceptors.add(dedupe.entrada)
    ..interceptors.add(dedupe.saida);
}

void main() {
  test('GETs iguais em andamento fazem uma chamada só', () async {
    final adapter = _Adapter();
    final dio = _dio(adapter);
    final a = dio.get('https://x.test/a?p=1');
    final b = dio.get('https://x.test/a?p=1');
    await Future<void>.delayed(Duration.zero);
    adapter.portao.complete();
    final r = await Future.wait([a, b]);
    expect(adapter.chamadas, 1);
    expect(r[1].data, r[0].data);
  });

  test('query diferente não junta', () async {
    final adapter = _Adapter()..portao.complete();
    final dio = _dio(adapter);
    await Future.wait([
      dio.get('https://x.test/a?p=1'),
      dio.get('https://x.test/a?p=2'),
    ]);
    expect(adapter.chamadas, 2);
  });

  test('se o primeiro falha, o segundo faz a própria chamada', () async {
    final adapter = _Adapter()..falha = true;
    final dio = _dio(adapter);
    final a = dio.get('https://x.test/a').catchError(
      (_) => Response(requestOptions: RequestOptions()),
    );
    final b = dio.get('https://x.test/a');
    await Future<void>.delayed(Duration.zero);
    adapter.portao.complete();
    await a;
    expect((await b).statusCode, 200);
    expect(adapter.chamadas, 2);
  });
}
