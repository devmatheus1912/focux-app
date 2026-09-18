import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'tls_certificate_pinning.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
///
/// Pin connect-time via [TlsCertificatePinning.createPinnedHttpClient].
/// [recycleHttpConnectionPool] troca o [IOHttpClientAdapter] (Dio descarta
/// `_cachedHttpClient`) e fecha o anterior **sem force**, com atraso — nunca
/// aborta POST /auth/ em voo quando o sheet Apple dispara `resumed`.
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

/// Pausa mínima antes de reciclar no resume (sheet Apple/Google costuma ser
/// mais curto; reciclar no meio do POST abortava o identityToken).
const kHttpPoolResumeRecycleMinAway = Duration(seconds: 5);

/// Atraso para fechar o adapter antigo sem force (deixa in-flight terminar).
const kHttpPoolStaleAdapterCloseDelay = Duration(seconds: 5);

/// Troca o adapter para Dio criar HttpClient novo (sockets idle mortos).
///
/// O adapter anterior fecha com `force: false` após [kHttpPoolStaleAdapterCloseDelay]
/// — `force: true` no resume matava o POST Apple em andamento.
void recycleHttpConnectionPool(Dio dio) {
  final previous = dio.httpClientAdapter;
  TlsCertificatePinning.apply(dio);
  configureHttpConnectionPool(dio);
  if (identical(previous, dio.httpClientAdapter)) return;

  Future<void>.delayed(kHttpPoolStaleAdapterCloseDelay, () {
    try {
      previous.close(force: false);
    } catch (_) {}
  });
}
