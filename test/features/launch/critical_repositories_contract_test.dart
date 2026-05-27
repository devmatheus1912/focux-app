import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/config/env.dart';

void main() {
  test('critical repositories call expected API paths', () {
    final checks = {
      'lib/features/convites/data/convite_repository.dart': '/api/convites',
      'lib/features/captura/data/captura_repository.dart': '/api/captura',
      'lib/features/financeiro/data/financeiro_repository.dart':
          '/api/financeiro',
      'lib/features/suporte/data/suporte_repository.dart': '/api/suporte',
      'lib/features/perfil/data/white_label_repository.dart':
          '/api/personal/white-label',
    };

    for (final entry in checks.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(source, contains(entry.value));
    }
  });

  test('public URLs use configurable base (Railway default)', () {
    expect(Env.capturaPageUrl('demo'), contains('/c/demo'));
    expect(Env.landingPageUrl('demo'), contains('/p/demo'));
    expect(Env.isProd, isTrue);
  });
}
