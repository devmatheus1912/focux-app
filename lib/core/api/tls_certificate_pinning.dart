import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// TLS pinning para Dio **e** WebSocket (via [HttpOverrides.global]).
///
/// Pinning aplica **somente** aos hosts da API/WS ([Env.apiUrl], [Env.wsUrl]).
/// Outros HTTPS (Google Fonts, Firebase, etc.) usam TLS padrão do sistema.
///
/// Pin no Dio é **connect-time** via [HttpClient.connectionFactory]
/// ([createPinnedHttpClient]). Em Dio 5.9.x, [IOHttpClientAdapter.validateCertificate]
/// só roda depois de `request.close()` — o body (senha / identityToken) já
/// saiu na rede; por isso validateCertificate é só defesa em profundidade.
class TlsCertificatePinning {
  TlsCertificatePinning._();

  static bool _overridesInstalled = false;

  /// Hosts que exigem certificate pinning (lowercase).
  @visibleForTesting
  static Set<String> pinnedHosts() {
    final hosts = <String>{};
    for (final raw in [Env.apiUrl, Env.wsUrl]) {
      if (raw.isEmpty) continue;
      try {
        hosts.add(Uri.parse(raw).host.toLowerCase());
      } catch (_) {
        // Ignora URL malformada em testes.
      }
    }
    return hosts;
  }

  @visibleForTesting
  static bool shouldPinHost(String host) {
    return pinnedHosts().contains(host.toLowerCase());
  }

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

  /// Aplica pinning no Dio: connect-time ([createPinnedHttpClient]) +
  /// validateCertificate (pós-response, defesa em profundidade).
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
      validateCertificate: (cert, host, port) {
        if (!shouldPinHost(host)) return true;
        return matches(cert, pins);
      },
    );
  }

  /// HttpClient real — sem reentrar em [HttpOverrides] (evita stack overflow).
  /// Usado por [createPinnedHttpClient] (Dio + WebSocket).
  static HttpClient baseHttpClient({SecurityContext? context}) {
    return HttpOverrides.runWithHttpOverrides(
      () => HttpClient(context: context),
      _DirectHttpOverrides(),
    );
  }

  /// Pin só quando há pins configurados. Sideload sem [Env.apiCertPins]
  /// não pode rejeitar o certificado do Railway (o pool HTTP reusa este client).
  @visibleForTesting
  static bool shouldEnforcePin(String host, Set<String> allowed) {
    return allowed.isNotEmpty && shouldPinHost(host);
  }

  static HttpClient createPinnedHttpClient([Set<String>? pins]) {
    final allowed = pins ?? _allowedPins();
    final client = baseHttpClient();
    if (allowed.isEmpty) {
      return client;
    }
    client.connectionFactory = _connectionFactory(allowed);
    return client;
  }

  static Future<ConnectionTask<Socket>> Function(
    Uri url,
    String? proxyHost,
    int? proxyPort,
  ) _connectionFactory(Set<String> allowed) {
    return (Uri uri, String? proxyHost, int? proxyPort) {
      final host = uri.host;
      final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
      if (uri.scheme != 'https' && uri.scheme != 'wss') {
        return Socket.startConnect(host, port);
      }
      if (!shouldEnforcePin(host, allowed)) {
        return SecureSocket.startConnect(host, port);
      }
      // Connect-time pin: rejeita leaf antes de qualquer byte HTTP.
      SecureSocket? sock;
      final Future<Socket> future = SecureSocket.connect(host, port).then((s) {
        sock = s;
        if (!matches(s.peerCertificate, allowed)) {
          s.destroy();
          throw const TlsException('Certificate pin mismatch');
        }
        return s;
      });
      return Future<ConnectionTask<Socket>>.value(
        ConnectionTask.fromSocket(future, () {
          try {
            sock?.destroy();
          } catch (_) {}
        }),
      );
    };
  }

  static bool matches(X509Certificate? cert, [Set<String>? pins]) {
    if (cert == null) return false;
    final allowed = pins ?? _allowedPins();
    if (allowed.isEmpty) return true;
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

/// Delegates para o [HttpOverrides] padrão — usado para escapar overrides globais.
class _DirectHttpOverrides extends HttpOverrides {}
