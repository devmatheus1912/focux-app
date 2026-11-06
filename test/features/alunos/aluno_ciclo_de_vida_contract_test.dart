import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Tela de alunos não monta repositório nem chama Dio: passa pelos providers
/// (`alunoRepositoryProvider`, `alunoCicloDeVidaProvider`). Repositório criado
/// na tela pula o seam dos testes e a limpeza das Homes.
void main() {
  test('UI de alunos usa providers, não repositório nem Dio direto', () {
    final failures = <String>[];
    for (final dir in const [
      'lib/features/alunos/screens',
      'lib/features/alunos/widgets',
      'lib/features/alunos/utils',
    ]) {
      for (final file in Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final path = file.path.replaceAll(r'\', '/');
        final norm = path.substring(path.indexOf('lib/'));
        final source = file.readAsStringSync();
        if (source.contains('AlunoRepository(')) {
          failures.add('$norm: AlunoRepository(');
        }
        if (source.contains('.dio.')) {
          failures.add('$norm: .dio.');
        }
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'Use alunoRepositoryProvider / alunoCicloDeVidaProvider.',
    );
  });
}
