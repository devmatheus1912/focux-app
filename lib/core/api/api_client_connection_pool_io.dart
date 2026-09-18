import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'tls_certificate_pinning.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
///
/// Pin connect-time via [TlsCertificatePinning.createPinnedHttpClient].
/// [recycleHttpConnectionPool] só troca o adapter — **nunca** chama close no
/// adapter anterior. Fechar (mesmo `force: false`) marca o HttpClient como
/// closed e o POST Apple em voo vira `StateError: Client is closed`.
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

/// Resume só recicla após background longo. Sheet Apple facilmente passa de 5s.
const kHttpPoolResumeRecycleMinAway = Duration(seconds: 30);

/// Troca o adapter para Dio criar HttpClient novo (sockets idle mortos).
///
/// O adapter anterior é **abandonado** (sem `close`). IdleTimeout mata
/// keep-alives; close explícito causava `Client is closed` no login Apple.
void recycleHttpConnectionPool(Dio dio) {
  TlsCertificatePinning.apply(dio);
  configureHttpConnectionPool(dio);
}
