import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every feature screen exposes root a11y scope', () {
    const allowedWithoutA11y = {'lib/features/qa/screens/qa_smoke_screen.dart'};

    final failures = <String>[];
    final root = Directory('lib/features');
    final screens = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'));

    for (final file in screens) {
      final path = file.path.replaceAll(r'\', '/');
      final normalized = path.substring(path.indexOf('lib/'));
      if (allowedWithoutA11y.contains(normalized)) continue;

      final source = file.readAsStringSync();
      final hasA11y =
          source.contains('Semantics(') ||
          source.contains('fxScreenA11yScope(');
      if (!hasA11y) {
        failures.add(normalized);
      }
    }

    expect(
      failures,
      isEmpty,
      reason:
          'Screens without Semantics/fxScreenA11yScope:\n${failures.join('\n')}',
    );
  });
}
