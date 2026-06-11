import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gate de auditoria: todo repository de feature deve chamar a API REST.
void main() {
  test('all feature repositories reference /api/ endpoints', () {
    final repos = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_repository.dart'))
        .toList();

    expect(repos, isNotEmpty, reason: 'nenhum repository encontrado');

    final failures = <String>[];
    for (final file in repos) {
      final source = file.readAsStringSync();
      if (!source.contains('/api/')) {
        failures.add(file.path);
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'repositories sem /api/: ${failures.join(', ')}',
    );
  });
}
