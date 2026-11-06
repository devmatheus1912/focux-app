import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Concluir a ativação mora em `concluirOnboarding` (servidor + o que fica
/// velho). Wizard e trava de recurso tinham listas próprias e já divergiam.
void main() {
  test('só concluirOnboarding marca o onboarding como completo', () {
    const permitidos = {
      'lib/features/onboarding/data/onboarding_repository.dart',
      'lib/features/onboarding/providers/onboarding_provider.dart',
    };
    final failures = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (permitidos.contains(norm)) continue;
      if (file.readAsStringSync().contains('marcarCompleto(')) {
        failures.add(norm);
      }
    }
    expect(failures, isEmpty, reason: 'Use concluirOnboarding(ref).');
  });
}
