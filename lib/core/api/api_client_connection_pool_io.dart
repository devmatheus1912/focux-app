import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'tls_certificate_pinning.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
///
/// Sem pins, [TlsCertificatePinning.createPinnedHttpClient] devolve um
/// HttpClient normal — não pode pin-mismatch em sideload/release sem
/// `API_CERT_PINS`.
HttpClient? _pooledClient;

void configureHttpConnectionPool(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }
  adapter.createHttpClient = () {
    final client = TlsCertificatePinning.createPinnedHttpClient();
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
