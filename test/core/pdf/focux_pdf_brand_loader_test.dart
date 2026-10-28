import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_brand_loader.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.resposta);

  final ResponseBody Function() resposta;
  int chamadas = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    chamadas++;
    return resposta();
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('baixa o logo e devolve imagem para o PDF', () async {
    final adapter = _Adapter(() => ResponseBody.fromBytes(_png, 200));
    final dio = Dio()..httpClientAdapter = adapter;
    final logo = await baixarLogoParaPdf('https://cdn.test/logo.png', dio: dio);
    expect(logo, isNotNull);
    expect(adapter.chamadas, 1);
  });

  test('URL vazia ou que não é http não faz requisição', () async {
    final adapter = _Adapter(() => ResponseBody.fromBytes(_png, 200));
    final dio = Dio()..httpClientAdapter = adapter;
    expect(await baixarLogoParaPdf(null, dio: dio), isNull);
    expect(await baixarLogoParaPdf('  ', dio: dio), isNull);
    expect(await baixarLogoParaPdf('file:///logo.png', dio: dio), isNull);
    expect(adapter.chamadas, 0);
  });

  test('erro de rede ou corpo vazio vira "sem logo", nunca exceção', () async {
    final falha = _Adapter(
      () => throw DioException(requestOptions: RequestOptions(path: '/')),
    );
    expect(
      await baixarLogoParaPdf(
        'https://cdn.test/x.png',
        dio: Dio()..httpClientAdapter = falha,
      ),
      isNull,
    );
    final vazio = _Adapter(() => ResponseBody.fromBytes(Uint8List(0), 200));
    expect(
      await baixarLogoParaPdf(
        'https://cdn.test/x.png',
        dio: Dio()..httpClientAdapter = vazio,
      ),
      isNull,
    );
  });
}
