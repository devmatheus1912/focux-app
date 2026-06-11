import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

void main() {
  const hubs = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
  ];

  test('hub screens expõem a11y scope e labels em controles', () {
    for (final path in hubs) {
      final source = readScreenSourceBundle(path);
      expect(
        source,
        anyOf(contains('fxScreenA11yScope'), contains('Semantics(')),
        reason: '$path sem escopo a11y',
      );
      expect(
        source,
        anyOf(
          contains('Semantics(label:'),
          contains('Semantics( label:'),
          contains('label:'),
          contains('tooltip:'),
          contains('semanticsLabel:'),
        ),
        reason: '$path sem labels em controles',
      );
    }
  });
}
