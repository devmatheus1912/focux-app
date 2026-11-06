import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Stale-while-revalidate de BFF mora em `lerSnapshotBff` / `BffSnapshotCache`.
/// Provider que escreve o SWR à mão (stale + claim de refresh) volta a
/// espalhar o protocolo: bug de 304 ou de refresh duplo vira N bugs.
void main() {
  test('SWR escrito à mão só no snapshot e no 360 (cache por aluno)', () {
    const permitidos = {
      'lib/core/api/bff_snapshot_cache.dart',
      // 360: cache por aluno com três partes, outro formato. Candidato a migrar.
      'lib/features/alunos/providers/aluno_detail_providers.dart',
      'lib/features/alunos/utils/aluno360_client_cache.dart',
    };
    final failures = <String>[];
    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (permitidos.contains(norm)) continue;
      final source = file.readAsStringSync();
      if (RegExp(r'claim\w*Refresh\(').hasMatch(source) &&
          source.contains('EvenIfStale(')) {
        failures.add(norm);
      }
    }
    expect(failures, isEmpty, reason: 'Use BffSnapshotCache + lerSnapshotBff.');
  });
}
