import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/tls_certificate_pinning.dart';

void main() {
  test('pinnedHosts inclui host da API de producao', () {
    final hosts = TlsCertificatePinning.pinnedHosts();
    expect(hosts, contains('api.focuxpersonal.com'));
  });

  test('shouldPinHost restringe pinning ao backend', () {
    expect(
      TlsCertificatePinning.shouldPinHost('api.focuxpersonal.com'),
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
      TlsCertificatePinning.shouldEnforcePin('api.focuxpersonal.com', const {}),
      isFalse,
    );
    expect(
      TlsCertificatePinning.shouldEnforcePin('api.focuxpersonal.com', {
        'sha256/abc',
      }),
      isTrue,
    );
  });

  test('baseHttpClient nao reentra no HttpOverrides global', () {
    HttpOverrides.global = _PinnedHttpOverrides({'sha256/test'});
    addTearDown(() => HttpOverrides.global = null);
    expect(() => TlsCertificatePinning.baseHttpClient(), returnsNormally);
  });

  test('Dio apply/pool usam createPinnedHttpClient (connect-time pin)', () {
    final pinning =
        File('lib/core/api/tls_certificate_pinning.dart').readAsStringSync();
    final pool =
        File('lib/core/api/api_client_connection_pool_io.dart').readAsStringSync();
    expect(pinning, contains('createPinnedHttpClient(pins)'));
    expect(pinning, contains('validateCertificate'));
    expect(pinning, contains('request.close()'));
    expect(pool, contains('createPinnedHttpClient()'));
    // recycle troca o adapter — não só fecha o client cacheado do Dio.
    expect(pool, contains('TlsCertificatePinning.apply(dio)'));
    expect(pool, contains('previous.close(force: true)'));
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
