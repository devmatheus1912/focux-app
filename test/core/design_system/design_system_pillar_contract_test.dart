import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 4 — Design system: tokens centralizados, catálogo Fx e hubs alinhados.
void main() {
  const tokenSources = [
    'lib/core/theme/design_tokens.dart',
    'lib/core/theme/tokens_strip.dart',
    'lib/core/theme/brand_palette.dart',
    'lib/core/theme/app_theme.dart',
    'lib/core/theme/app_typography.dart',
  ];

  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  // (?<!Pdf) — PdfColors do pacote pdf não são tema Flutter (export A4).
  final semanticColorPattern = RegExp(
    r'(?<!Pdf)Colors\.(red|green|blue|orange|purple|pink|yellow|teal|cyan|amber|indigo|brown|grey|gray|lime|deepOrange|deepPurple|lightBlue|lightGreen)',
  );

  const excludedPrefixes = ['lib/features/qa/'];
  const excludedFiles = {
    'lib/features/relatorio/screens/relatorio_screen.dart',
    'lib/features/anamnese/screens/anamnese_screen.dart',
  };

  test('token source files and design system doc exist', () {
    for (final path in tokenSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Token ausente: $path');
    }
    expect(
      File('docs/DESIGN_SYSTEM.md').existsSync(),
      isTrue,
      reason: 'docs/DESIGN_SYSTEM.md ausente',
    );
    expect(
      File('lib/features/qa/screens/tokens_strip_showcase_screen.dart').existsSync(),
      isTrue,
      reason: 'Showcase TOKENS STRIP ausente',
    );
  });

  test('TokensStrip version is documented in showcase', () {
    final showcase = File(
      'lib/features/qa/screens/tokens_strip_showcase_screen.dart',
    ).readAsStringSync();
    expect(showcase, contains('TokensStrip.version'));
    expect(showcase, contains('TOKENS STRIP'));
  });

  test('minimum Fx core widget catalog', () {
    final fxWidgets = Directory('lib/core/widgets')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.replaceAll(r'\', '/').contains('/fx_'))
        .length;
    expect(fxWidgets, greaterThanOrEqualTo(15));
  });

  test('hub screens import centralized theme tokens', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final usesTokens = source.contains('design_tokens.dart') ||
          source.contains('tokens_strip.dart') ||
          source.contains('brand_palette.dart') ||
          source.contains('shell_chrome.dart') ||
          source.contains('EagleTokens') ||
          source.contains('TokensStrip') ||
          source.contains('BrandPalette');
      expect(usesTokens, isTrue, reason: '$path deve usar tokens centralizados');
    }
  });

  test('features avoid semantic Material Colors literals', () {
    final failures = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (excludedPrefixes.any(norm.startsWith)) continue;
      if (excludedFiles.contains(norm)) continue;

      final source = file.readAsStringSync();
      for (final match in semanticColorPattern.allMatches(source)) {
        final line =
            '\n'.allMatches(source.substring(0, match.start)).length + 1;
        failures.add('$norm:$line ${match.group(0)}');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('macro nutrition tokens defined in EagleTokens', () {
    final tokens = File('lib/core/theme/design_tokens.dart').readAsStringSync();
    for (final name in ['macroProtein', 'macroCarb', 'macroFat']) {
      expect(tokens, contains(name), reason: 'EagleTokens.$name ausente');
    }
  });
}
