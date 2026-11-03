import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';

class _Adapter implements HttpClientAdapter {
  final chamadas = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas.add(options.path);
    return ResponseBody.fromString(
      jsonEncode({'content': [], 'alunos': [], 'hasNext': false}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
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

ProviderContainer _container(_Adapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
  final c = ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(_FakeApiClient(dio))],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('abrir a lista de alunos faz uma chamada só', () async {
    AlunosHomeClientCache.clear();
    final adapter = _Adapter();
    final c = _container(adapter);

    await c.read(alunosHomeProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(adapter.chamadas.where((p) => p == '/api/alunos/home'), hasLength(1));
  });

  test('abrir a Hoje carrega por uma rota só', () async {
    final adapter = _Adapter();
    final c = _container(adapter);

    try {
      await c.read(dashboardHomeProvider.future);
    } catch (_) {
      // Corpo mínimo do teste: importa quantas chamadas saíram, não o parse.
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(adapter.chamadas.toSet(), hasLength(1));
    expect(adapter.chamadas, hasLength(lessThanOrEqualTo(6)));
  });
}
