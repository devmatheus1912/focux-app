import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/account/excluir_conta_flow.dart';

class _Status implements HttpClientAdapter {
  _Status(this.corpo, {this.codigo = 200});

  final Map<String, dynamic> corpo;
  final int codigo;
  String? caminho;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    caminho = options.path;
    return ResponseBody.fromString(
      jsonEncode(corpo),
      codigo,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_Status a) => Dio()..httpClientAdapter = a;

void main() {
  test('conta sem senha conhecida no servidor vale em qualquer aparelho', () async {
    final a = _Status({'enabled': false, 'emailOtpPreferred': true});
    expect(await personalSemSenhaConhecida(_dio(a)), isTrue);
    expect(a.caminho, '/api/auth/mfa/status');
  });

  test('conta com senha: pede a senha', () async {
    final a = _Status({'enabled': false, 'emailOtpPreferred': false});
    expect(await personalSemSenhaConhecida(_dio(a)), isFalse);
  });

  test('erro de rede: não sabe, vale o memo do aparelho', () async {
    final a = _Status({}, codigo: 500);
    expect(await personalSemSenhaConhecida(_dio(a)), isFalse);
  });
}
