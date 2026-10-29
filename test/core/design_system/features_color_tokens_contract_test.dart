import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Features de produção não devem usar hex cru — tokens em EagleTokens/BrandPalette.
void main() {
  const excludedPrefixes = [
    'lib/features/qa/',
  ];
  const excludedFiles = {
    // Marca "G" do Google (cores oficiais) e botão social preto: cores de marca
    // de terceiros (Apple HIG / Google), não tokens do produto.
    'lib/features/auth/widgets/google_logo_mark.dart',
    'lib/features/auth/widgets/auth_social_button.dart',
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
