import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _aluno(int id) => {
  'id': id,
  'nome': 'Aluno $id',
  'status': 'ATIVO',
};

class _AlunosPageAdapter implements HttpClientAdapter {
  final List<String> paths = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add('${options.path}?page=${options.queryParameters['page']}');
    final page = int.parse('${options.queryParameters['page'] ?? 0}');
    final payload =
        page == 0
            ? {
              'content': [_aluno(1), _aluno(2)],
              'page': 0,
              'size': 100,
              'totalElements': 3,
              'hasNext': true,
            }
            : {
              'content': [_aluno(3)],
              'page': 1,
              'size': 100,
              'totalElements': 3,
              'hasNext': false,
            };
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RawListAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode([_aluno(1)]),
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

  late ApiClient client;
  late AlunoRepository repo;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    client = ApiClient();
    repo = AlunoRepository(client);
  });

  test('listarPagina lê o envelope do contrato, não a lista crua', () async {
    client.dio.httpClientAdapter = _AlunosPageAdapter();
    final pagina = await repo.listarPagina(page: 0, size: 20);

    expect(pagina.content.map((a) => a.id), [1, 2]);
    expect(pagina.hasNext, isTrue);
    expect(pagina.page, 0);
    expect(pagina.totalElements, 3);
    expect(pagina.isOffset, isTrue);
  });

  test('listar drena as páginas até hasNext false', () async {
    final adapter = _AlunosPageAdapter();
    client.dio.httpClientAdapter = adapter;

    final alunos = await repo.listar();

    expect(alunos.map((a) => a.id), [1, 2, 3]);
    expect(adapter.paths, hasLength(2));
  });

  test('lista crua falha alto: o endpoint não é mais um array', () async {
    client.dio.httpClientAdapter = _RawListAdapter();
    expect(repo.listarPagina(), throwsFormatException);
  });
}
