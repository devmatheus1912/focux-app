import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';

Map<String, Object> _ag(int id, String inicio) => {
  'id': id,
  'alunoId': 1,
  'alunoNome': 'Aluno Exemplo',
  'inicio': inicio,
  'fim': inicio.replaceFirst('T08', 'T09'),
  'status': 'AGENDADO',
};

class _Adapter implements HttpClientAdapter {
  _Adapter({required this.temMes});

  final bool temMes;
  final List<String> chamadas = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final q = options.queryParameters;
    chamadas.add('${options.path}?${q.values.join(',')}');
    Object? body;
    var status = 200;
    if (options.path == '/api/agenda/mes') {
      if (temMes) {
        body = [_ag(1, '2026-10-02T08:00:00')];
      } else {
        status = 404;
        body = {'erro': 'não existe'};
      }
    } else if (options.path == '/api/agenda/semana') {
      body =
          q['data'] == '2026-09-28'
              ? [_ag(1, '2026-10-02T08:00:00')]
              : q['data'] == '2026-10-05'
              ? [_ag(1, '2026-10-02T08:00:00'), _ag(2, '2026-10-06T08:00:00')]
              : <Object>[];
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
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

AgendaRepository _repo(_Adapter adapter) =>
    AgendaRepository(_FakeApiClient(Dio()..httpClientAdapter = adapter));

void main() {
  test('listarMes usa /api/agenda/mes', () async {
    final adapter = _Adapter(temMes: true);
    final items = await _repo(adapter).listarMes(2026, 10);
    expect(items.map((a) => a.id), [1]);
    expect(adapter.chamadas, ['/api/agenda/mes?2026,10']);
  });

  test('backend antigo: junta as 6 semanas sem duplicar', () async {
    final adapter = _Adapter(temMes: false);
    final items = await _repo(adapter).listarMes(2026, 10);
    expect(items.map((a) => a.id), [1, 2]);
    expect(adapter.chamadas.where((c) => c.startsWith('/api/agenda/semana')), [
      '/api/agenda/semana?2026-09-28',
      '/api/agenda/semana?2026-10-05',
      '/api/agenda/semana?2026-10-12',
      '/api/agenda/semana?2026-10-19',
      '/api/agenda/semana?2026-10-26',
      '/api/agenda/semana?2026-11-02',
    ]);
  });
}
