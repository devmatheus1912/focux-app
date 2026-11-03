import 'dart:async';

import 'package:dio/dio.dart';

const _kLider = 'fxDedupeLider';

/// GETs iguais em andamento viram um só: quem chega depois espera a resposta do primeiro.
/// Se o primeiro falhar, o seguinte faz a própria chamada.
class GetDedupe {
  final _emAndamento = <String, Completer<Response<dynamic>>>{};

  static String _chave(RequestOptions o) => o.uri.toString();

  /// Antes do interceptor principal.
  Interceptor get entrada => InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (options.method.toUpperCase() != 'GET' ||
          options.extra[_kLider] == true ||
          options.responseType == ResponseType.stream) {
        handler.next(options);
        return;
      }
      final chave = _chave(options);
      final emCurso = _emAndamento[chave];
      if (emCurso == null) {
        _emAndamento[chave] = Completer<Response<dynamic>>();
        options.extra[_kLider] = true;
        handler.next(options);
        return;
      }
      try {
        final r = await emCurso.future;
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            data: r.data,
            headers: r.headers,
            statusCode: r.statusCode,
            statusMessage: r.statusMessage,
          ),
          true,
        );
      } catch (_) {
        handler.next(options);
      }
    },
  );

  /// O `resolve` do onError não passa pela [saida]: quem resolve ali avisa aqui.
  void responder(Response<dynamic> response) =>
      _concluir(response.requestOptions, (c) => c.complete(response));

  /// Depois do interceptor principal: ali a resposta já é a final, com retry e cache aplicados.
  Interceptor get saida => InterceptorsWrapper(
    onResponse: (response, handler) {
      responder(response);
      handler.next(response);
    },
    onError: (e, handler) {
      _concluir(e.requestOptions, (c) {
        c.future.ignore();
        c.completeError(e);
      });
      handler.next(e);
    },
  );

  void _concluir(
    RequestOptions options,
    void Function(Completer<Response<dynamic>>) fim,
  ) {
    if (options.extra[_kLider] != true) return;
    final c = _emAndamento.remove(_chave(options));
    if (c != null && !c.isCompleted) fim(c);
  }
}
