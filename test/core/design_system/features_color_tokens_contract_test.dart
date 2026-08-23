import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Features de produção não devem usar hex cru — tokens em EagleTokens/BrandPalette.
void main() {
  const excludedPrefixes = [
    'lib/features/qa/',
  ];
  const excludedFiles = {
    'lib/features/auth/widgets/google_sign_in_button.dart',
    'lib/features/dashboard/utils/dashboard_readability.dart',
    // Parser de hex do white-label — constrói Color a partir de string, não é token.
    'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
  };

  test('features evitam Color(0x literais', () {
    final root = Directory('lib/features');
    final failures = <String>[];

    for (final file in root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (excludedPrefixes.any(norm.startsWith)) continue;
      if (excludedFiles.contains(norm)) continue;

      if (file.readAsStringSync().contains('Color(0x')) {
        failures.add(norm);
      }
    }

    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
