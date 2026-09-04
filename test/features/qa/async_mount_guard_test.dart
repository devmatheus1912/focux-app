import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual QA screens guard async reloads before setState', () {
    for (final path in [
      'lib/features/agenda/screens/agenda_screen.dart',
      'lib/features/avaliacao/screens/evolucao_comparativo_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();

      expect(
        source,
        contains('if (!mounted) return;'),
        reason: '$path must avoid setState after dispose during route QA.',
      );
    }
  });
}
