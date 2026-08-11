import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// TLS pinning para Dio **e** WebSocket (via [HttpOverrides.global]).
class TlsCertificatePinning {
  TlsCertificatePinning._();

  static bool _overridesInstalled = false;

  /// Instalar cedo no [main] — cobre `WebSocket.connect` / STOMP / HttpClient.
  static void installGlobalOverrides() {
    if (kIsWeb || _overridesInstalled) return;
    final pins = _allowedPins();
    if (pins.isEmpty) {
      if (kReleaseMode && Env.requireApiCertPins) {
        throw StateError(
          'API_CERT_PINS obrigatório em release. '
          'Passe --dart-define=API_CERT_PINS=sha256/...',
        );
      }
      return;
    }
    HttpOverrides.global = _PinnedHttpOverrides(pins);
    _overridesInstalled = true;
  }

  static void apply(Dio dio) {
    if (kIsWeb) return;
    final pins = _allowedPins();
    if (pins.isEmpty) {
      if (kReleaseMode && Env.requireApiCertPins) {
        throw StateError(
          'API_CERT_PINS obrigatório em release. '
          'Passe --dart-define=API_CERT_PINS=sha256/...',
        );
      }
      return;
    }

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () => createPinnedHttpClient(pins),
      validateCertificate: (cert, host, port) => matches(cert, pins),
    );
  }

  static HttpClient createPinnedHttpClient([Set<String>? pins]) {
    final allowed = pins ?? _allowedPins();
    final client = HttpClient();
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) {
      final host = uri.host;
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      if (uri.scheme != 'https' && uri.scheme != 'wss') {
        return Socket.startConnect(host, port);
      }
      final Future<Socket> future =
          SecureSocket.connect(host, port).then((SecureSocket sock) {
        if (!matches(sock.peerCertificate, allowed)) {
          sock.destroy();
          throw const TlsException('Certificate pin mismatch');
        }
        return sock;
      });
      return Future<ConnectionTask<Socket>>.value(
        ConnectionTask.fromSocket(future, () {}),
      );
    };
    return client;
  }

  static bool matches(X509Certificate? cert, [Set<String>? pins]) {
    if (cert == null) return false;
    final allowed = pins ?? _allowedPins();
    if (allowed.isEmpty) return !kReleaseMode;
    final digest = sha256.convert(cert.der);
    final b64 = base64.encode(digest.bytes);
    final hex = digest.bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final candidates = <String>{
      'sha256/$b64',
      b64,
      hex,
      'sha256/$hex',
    }.map((c) => c.toLowerCase());
    return candidates.any(allowed.contains);
  }

  static Set<String> _allowedPins() {
    return Env.apiCertPins
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toSet();
  }
}

class _PinnedHttpOverrides extends HttpOverrides {
  _PinnedHttpOverrides(this.pins);
  final Set<String> pins;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return TlsCertificatePinning.createPinnedHttpClient(pins);
  }
}
