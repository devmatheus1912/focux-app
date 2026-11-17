import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Google Play (17/11/2026): Health Connect só com os tipos que o app mostra
/// (escopo mínimo). HRV no Android foi recusado: não volta sem uma tela que use.
void main() {
  test('Android não pede variabilidade da FC ao Health Connect', () {
    final manifesto = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifesto, isNot(contains('READ_HEART_RATE_VARIABILITY')));
    expect(
      File('lib/core/health/health_service.dart').readAsStringSync(),
      isNot(contains('HEART_RATE_VARIABILITY_RMSSD')),
    );
  });
}
