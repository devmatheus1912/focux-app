import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/tls_certificate_pinning.dart';

void main() {
  test('pinnedHosts inclui host da API de producao', () {
    final hosts = TlsCertificatePinning.pinnedHosts();
    expect(
      hosts,
      contains('focux-backend-production.up.railway.app'),
    );
  });

  test('shouldPinHost restringe pinning ao backend', () {
    expect(
      TlsCertificatePinning.shouldPinHost(
        'focux-backend-production.up.railway.app',
      ),
      isTrue,
    );
    expect(
      TlsCertificatePinning.shouldPinHost('fonts.gstatic.com'),
      isFalse,
    );
    expect(
      TlsCertificatePinning.shouldPinHost('firebase.googleapis.com'),
      isFalse,
    );
  });

  test('sem pins o host da API usa TLS do sistema', () {
    expect(
      TlsCertificatePinning.shouldEnforcePin(
        'focux-backend-production.up.railway.app',
        const {},
      ),
      isFalse,
    );
    expect(
      TlsCertificatePinning.shouldEnforcePin(
        'focux-backend-production.up.railway.app',
        {'sha256/abc'},
      ),
      isTrue,
    );
  });

  test('baseHttpClient nao reentra no HttpOverrides global', () {
    HttpOverrides.global = _PinnedHttpOverrides({'sha256/test'});
    addTearDown(() => HttpOverrides.global = null);
    expect(() => TlsCertificatePinning.baseHttpClient(), returnsNormally);
  });
}

class _PinnedHttpOverrides extends HttpOverrides {
  _PinnedHttpOverrides(this.pins);
  final Set<String> pins;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    throw StateError('nao deveria reentrar');
  }
}
