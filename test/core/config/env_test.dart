import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';

void main() {
  test('landing and captura URLs use public web base', () {
    expect(
      Env.landingPageUrl('joao'),
      '${Env.publicWebUrl}/p/joao',
    );
    expect(
      Env.capturaPageUrl('joao'),
      '${Env.publicWebUrl}/c/joao',
    );
  });

  test('wsUrl derives from apiUrl', () {
    expect(Env.wsUrl, startsWith('wss://'));
    expect(Env.wsUrl, contains('focuxpersonal.com'));
  });

  test('isProd detects brand API host', () {
    expect(Env.isProd, isTrue);
  });

  test('sem pins embutidos: renovação do certificado não derruba o app', () {
    expect(Env.apiCertPins, isEmpty);
    expect(Env.requireApiCertPins, isFalse);
  });
}
