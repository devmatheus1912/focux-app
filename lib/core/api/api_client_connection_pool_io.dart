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
/// Sempre atribui um [IOHttpClientAdapter] novo: se [TlsCertificatePinning.apply]
/// no-op (pins vazios em sideload/staging), ainda assim Dio descarta
/// `_cachedHttpClient`. O adapter anterior é abandonado — sem `close`.
void recycleHttpConnectionPool(Dio dio) {
  final before = dio.httpClientAdapter;
  TlsCertificatePinning.apply(dio);
  if (identical(dio.httpClientAdapter, before)) {
    // Pins vazios: apply não troca o adapter — força instância nova.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: TlsCertificatePinning.baseHttpClient,
    );
  }
  configureHttpConnectionPool(dio);
}
