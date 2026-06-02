import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Tunes the native HTTP client for many parallel API calls (dashboard + sync).
void configureHttpConnectionPool(Dio dio) {
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) {
    return;
  }
  adapter.createHttpClient = () {
    final client = HttpClient();
    client.maxConnectionsPerHost = 8;
    client.idleTimeout = const Duration(seconds: 20);
    return client;
  };
}
