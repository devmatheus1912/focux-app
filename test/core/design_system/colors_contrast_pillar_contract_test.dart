import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 7 — Cores & contraste: tokens semânticos, WCAG e hubs alinhados.
void main() {
  const contrastSources = [
    'lib/core/theme/focux_contrast.dart',
    'lib/core/theme/design_tokens.dart',
    'lib/core/theme/curated_brand_palettes.dart',
    'lib/core/theme/brand_palette.dart',
    'lib/features/dashboard/utils/dashboard_readability.dart',
    'lib/features/alunos/utils/aluno360_readability.dart',
  ];

  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('contrast and readability source files exist', () {
    for (final path in contrastSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    expect(
      File('test/core/theme/focux_contrast_test.dart').existsSync(),
      isTrue,
      reason: 'Testes unitários de contraste ausentes',
    );
    expect(
      File('test/core/design_system/features_color_tokens_contract_test.dart')
          .existsSync(),
      isTrue,
      reason: 'Gate de hex cru ausente',
    );
  });

  test('DESIGN_SYSTEM documents colors and contrast', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Cores & contraste'));
    expect(doc, contains('FocuxContrast'));
    expect(doc, contains('WCAG'));
    expect(doc, contains('colors_contrast_pillar_contract_test'));
  });

  test('EagleTokens semantic colors and score helpers defined', () {
    final tokens = File('lib/core/theme/design_tokens.dart').readAsStringSync();
    for (final name in [
      'semanticGood',
      'semanticWarn',
      'semanticBad',
      'goodDark',
      'warnDark',
      'badDark',
      'aderenciaColor',
      'scoreColor',
    ]) {
      expect(tokens, contains(name), reason: 'EagleTokens.$name ausente');
    }
  });

  test('FocuxContrast exposes WCAG helpers', () {
    final source = File('lib/core/theme/focux_contrast.dart').readAsStringSync();
    for (final symbol in [
      'contrastRatio',
      'meetsWcagAa',
      'readableOn',
      'wcagAaNormal',
    ]) {
      expect(source, contains(symbol), reason: 'FocuxContrast.$symbol ausente');
    }
  });

  test('CuratedBrandPalette validates readable primaries', () {
    final source =
        File('lib/core/theme/curated_brand_palettes.dart').readAsStringSync();
    expect(source, contains('isReadablePrimary'));
    expect(source, contains('FocuxContrast'));
  });

  test('hub screens use centralized color or readability tokens', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final usesColorTokens = source.contains('design_tokens.dart') ||
          source.contains('tokens_strip.dart') ||
          source.contains('brand_palette.dart') ||
          source.contains('shell_chrome.dart') ||
          source.contains('dashboard_readability') ||
          source.contains('aluno360_readability') ||
          source.contains('EagleTokens') ||
          source.contains('TokensStrip') ||
          source.contains('BrandPalette') ||
          source.contains('semanticGood') ||
          source.contains('semanticWarn') ||
          source.contains('semanticBad');
      expect(
        usesColorTokens,
        isTrue,
        reason: '$path deve usar tokens de cor ou legibilidade',
      );
    }
  });
}
