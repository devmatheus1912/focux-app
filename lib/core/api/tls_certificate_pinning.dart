import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// TLS pinning para API principal, pagamento e IAP (`API_CERT_PINS`).
///
/// Usa [IOHttpClientAdapter.validateCertificate] (chamado em **todo** handshake),
/// não [HttpClient.badCertificateCallback] (só cert inválido — pinning nunca rodava).
class TlsCertificatePinning {
  TlsCertificatePinning._();

  static void apply(Dio dio) {
    if (kIsWeb) return;
    final pins = Env.apiCertPins;
    if (pins.isEmpty) {
      if (kReleaseMode && Env.requireApiCertPins) {
        throw StateError(
          'API_CERT_PINS obrigatório em release (REQUIRE_API_CERT_PINS=true).',
        );
      }
      return;
    }

    final allowed = pins
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toSet();

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: HttpClient.new,
      validateCertificate: (cert, host, port) {
        if (cert == null) return false;
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
      },
    );
  }
}
