import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 5 — Tipografia: escala centralizada, sem GoogleFonts direto em features.
void main() {
  const typographySources = [
    'lib/core/theme/app_typography.dart',
    'lib/core/theme/focux_typography.dart',
    'lib/core/theme/tokens_strip.dart',
    'lib/core/theme/app_theme.dart',
  ];

  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  const moduleTypographyUtils = [
    'lib/features/financeiro/utils/financeiro_typography.dart',
  ];

  test('typography source files and scale constants exist', () {
    for (final path in typographySources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    final strip = File('lib/core/theme/tokens_strip.dart').readAsStringSync();
    for (final name in [
      'fontH1',
      'fontH2',
      'fontBody',
      'fontBodySm',
      'weightH1',
      'weightH2',
    ]) {
      expect(strip, contains(name), reason: 'TokensStrip.$name ausente');
    }
    final focux = File('lib/core/theme/focux_typography.dart').readAsStringSync();
    for (final name in ['monoMetric', 'headline', 'body', 'kpiCondensed']) {
      expect(focux, contains(name), reason: 'FocuxTypography.$name ausente');
    }
  });

  test('app theme builds textTheme via AppTypography', () {
    final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(theme, contains('AppTypography.inter'));
    expect(theme, contains('AppTypography.mono'));
    expect(theme, contains('textTheme:'));
    expect(theme, contains('TokensStrip.fontH1'));
  });

  test('module typography utils exist for complex hubs', () {
    for (final path in moduleTypographyUtils) {
      expect(File(path).existsSync(), isTrue, reason: 'Util ausente: $path');
      final source = File(path).readAsStringSync();
      expect(source, contains('AppTypography'));
    }
  });

  test('hub screens use centralized typography', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final usesTypography = source.contains('AppTypography') ||
          source.contains('FocuxTypography') ||
          source.contains('FinanceiroTypography') ||
          source.contains('TokensStrip.h1') ||
          source.contains('TokensStrip.h2') ||
          source.contains('TokensStrip.body') ||
          source.contains('TokensStrip.fontH') ||
          source.contains('textTheme') ||
          source.contains('Theme.of(context)');
      expect(usesTypography, isTrue, reason: '$path deve usar tipografia centralizada');
    }
  });

  test('features do not call GoogleFonts directly', () {
    final failures = <String>[];
    for (final file in Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final path = file.path.replaceAll(r'\', '/');
      final norm = path.substring(path.indexOf('lib/'));
      if (norm.startsWith('lib/features/qa/')) continue;

      final source = file.readAsStringSync();
      if (source.contains('GoogleFonts.')) {
        failures.add(norm);
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('DESIGN_SYSTEM documents typography', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Tipografia'));
    expect(doc, contains('AppTypography'));
    expect(doc, contains('FocuxTypography'));
  });
}
