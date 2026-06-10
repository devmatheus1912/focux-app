import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every feature module ships repository (or data layer) + at least one screen.
void main() {
  test('all feature modules have data layer and screen', () {
    final features = Directory('lib/features')
        .listSync()
        .whereType<Directory>()
        .where((d) => !d.path.endsWith('qa'))
        .toList();

    final failures = <String>[];

    for (final module in features) {
      final name = module.path.split(Platform.pathSeparator).last;
      final files = module.listSync(recursive: true).whereType<File>().toList();
      final hasScreen = files.any((f) => f.path.endsWith('_screen.dart'));
      final hasData = files.any(
        (f) =>
            f.path.contains('_repository.dart') ||
            f.path.contains('/data/') && f.path.endsWith('.dart'),
      );

      final screenExempt = {'planos', 'pricing', 'pql', 'subscription'};
      if (!hasScreen && !screenExempt.contains(name)) {
        failures.add('$name: sem tela');
      }
      if (!hasData) {
        failures.add('$name: sem camada data/repository');
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
