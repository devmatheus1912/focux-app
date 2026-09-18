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

  test('apiCertPins inclui leaf pins em host de produção default', () {
    expect(Env.targetsKnownProdApi, isTrue);
    expect(Env.apiCertPins.length, greaterThanOrEqualTo(2));
    expect(
      Env.apiCertPins.any((p) => p.contains('56ZylJhguSmnkPgt0hUNGj')),
      isTrue,
    );
    expect(
      Env.apiCertPins.any((p) => p.contains('BWjzG+rPlj+2cnDnbI+4LLj9z1h')),
      isTrue,
    );
  });
}
