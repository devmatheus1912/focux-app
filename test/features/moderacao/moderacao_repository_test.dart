import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/features/moderacao/data/moderacao_repository.dart';

class _Adapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
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
  late ModeracaoRepository repo;

  setUp(() {
    adapter = _Adapter();
    repo = ModeracaoRepository(
      _FakeApiClient(Dio()..httpClientAdapter = adapter),
    );
  });

  Map<String, dynamic> body() {
    final data = adapter.last!.data;
    return (data is String ? jsonDecode(data) : data) as Map<String, dynamic>;
  }

  test('denúncia de mensagem vai para a moderação com tipo e motivo', () async {
    await repo.denunciar(
      tipo: DenunciaTipo.chatMensagem,
      motivo: DenunciaMotivo.assedio,
      alvoId: '42',
      detalhe: '  insistente  ',
      conteudo: 'texto da mensagem',
    );

    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '/api/moderacao/denuncias');
    expect(body(), {
      'tipo': 'CHAT_MENSAGEM',
      'alvoId': '42',
      'motivo': 'ASSEDIO',
      'detalhe': 'insistente',
      'conteudo': 'texto da mensagem',
    });
  });

  test('resposta da IA vai sem alvo e corta textos longos', () async {
    await repo.denunciar(
      tipo: DenunciaTipo.iaResposta,
      motivo: DenunciaMotivo.inadequado,
      detalhe: '   ',
      conteudo: 'x' * 3000,
    );

    final b = body();
    expect(b['tipo'], 'IA_RESPOSTA');
    expect(b['alvoId'], isNull);
    expect(b['detalhe'], isNull);
    expect((b['conteudo'] as String).length, ModeracaoRepository.conteudoMax);
  });
}
