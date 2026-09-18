import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'tls_certificate_pinning.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
///
/// Usa [TlsCertificatePinning.baseHttpClient] (sem `connectionFactory`).
/// Pinning do Dio fica em `validateCertificate` ([TlsCertificatePinning.apply]).
/// `createPinnedHttpClient` fica só para WebSocket / [HttpOverrides.global].
HttpClient? _pooledClient;

void configureHttpConnectionPool(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }
  adapter.createHttpClient = () {
    final client = TlsCertificatePinning.baseHttpClient();
    client.maxConnectionsPerHost = 8;
    client.idleTimeout = const Duration(seconds: 20);
    _pooledClient = client;
    return client;
  };
}

/// Fecha keep-alives mortos após longo background (OS suspende sockets).
void recycleHttpConnectionPool(Dio dio) {
  final stale = _pooledClient;
  _pooledClient = null;
  try {
    stale?.close(force: true);
  } catch (_) {}
  configureHttpConnectionPool(dio);
}
