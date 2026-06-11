import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Tier S+ a11y — todas as telas de produção expõem escopo e labels.
void main() {
  const excluded = {
    'lib/features/qa/screens/qa_smoke_screen.dart',
    'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
  };

  test('todas as feature screens expõem a11y scope e labels em controles', () {
    final screens = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_screen.dart'))
        .toList();

    final failures = <String>[];

    for (final file in screens) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (excluded.contains(norm)) continue;

      final source = readScreenSourceBundle(norm);

      if (!source.contains('fxScreenA11yScope') &&
          !source.contains('Semantics(')) {
        failures.add('$norm: sem escopo a11y');
        continue;
      }

      final hasLabels = source.contains('Semantics(label:') ||
          source.contains('Semantics( label:') ||
          source.contains('label:') ||
          source.contains('tooltip:') ||
          source.contains('semanticsLabel:');

      if (!hasLabels) {
        failures.add('$norm: sem labels em controles');
      }
    }

    expect(
      failures,
      isEmpty,
      reason: 'Telas sem a11y (${failures.length}):\n${failures.join('\n')}',
    );
  });
}
