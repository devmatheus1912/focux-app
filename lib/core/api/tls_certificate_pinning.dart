import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';

/// TLS pinning opcional para chamadas de pagamento/IAP (`API_CERT_PINS`).
class TlsCertificatePinning {
  TlsCertificatePinning._();

  static void apply(Dio dio) {
    if (kIsWeb) return;
    final pins = Env.apiCertPins;
    if (pins.isEmpty) return;

    final allowed = pins
        .map((p) => p.trim().toLowerCase())
        .where((p) => p.isNotEmpty)
        .toSet();

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) {
          final digest = sha256.convert(cert.der);
          final b64 = base64.encode(digest.bytes);
          final pin = 'sha256/$b64';
          return allowed.contains(pin) ||
              allowed.contains(b64) ||
              allowed.contains(digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join());
        };
        return client;
      },
    );
  }
}
