import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'tls_certificate_pinning.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
///
/// Pin connect-time via [TlsCertificatePinning.createPinnedHttpClient].
/// [recycleHttpConnectionPool] **substitui** o [IOHttpClientAdapter] inteiro —
/// só fechar o HttpClient deixa o `_cachedHttpClient` privado do Dio 5.9
/// apontando para um client já fechado (→ `DioException.unknown`).
void configureHttpConnectionPool(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }
  adapter.createHttpClient = () {
    final client = TlsCertificatePinning.createPinnedHttpClient();
    client.maxConnectionsPerHost = 8;
    client.idleTimeout = const Duration(seconds: 20);
    return client;
  };
}

/// Após background / sheet nativo: troca o adapter para Dio criar HttpClient novo.
void recycleHttpConnectionPool(Dio dio) {
  final previous = dio.httpClientAdapter;
  // Novo IOHttpClientAdapter ⇒ Dio descarta `_cachedHttpClient` fechado.
  TlsCertificatePinning.apply(dio);
  configureHttpConnectionPool(dio);
  if (!identical(previous, dio.httpClientAdapter)) {
    try {
      previous.close(force: true);
    } catch (_) {}
  }
}
