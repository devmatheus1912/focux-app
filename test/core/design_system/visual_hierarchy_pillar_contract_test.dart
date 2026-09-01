import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 8 — Hierarquia visual & foco: escala tipográfica, elevação e hubs.
void main() {
  const hierarchySources = [
    'lib/core/theme/focux_hub_typography.dart',
    'lib/core/theme/focux_typography.dart',
    'lib/core/theme/tokens_strip.dart',
    'lib/core/theme/shell_chrome.dart',
    'lib/core/widgets/fx_input_deco.dart',
  ];

  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('hierarchy and focus source files exist', () {
    for (final path in hierarchySources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    expect(
      File('test/core/theme/focux_hub_typography_test.dart').existsSync(),
      isTrue,
      reason: 'Testes unitários de hierarquia ausentes',
    );
  });

  test('DESIGN_SYSTEM documents visual hierarchy and focus', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Hierarquia visual & foco'));
    expect(doc, contains('FocuxHubTypography'));
    expect(doc, contains('visual_hierarchy_pillar_contract_test'));
  });

  test('hub typography and tokens expose type roles and elevation layers', () {
    final type = File('lib/core/theme/focux_hub_typography.dart').readAsStringSync();
    for (final symbol in ['pageTitle', 'sectionTitle', 'cardTitle', 'eyebrow']) {
      expect(type, contains(symbol), reason: 'FocuxHubTypography.$symbol ausente');
    }
    final strip = File('lib/core/theme/tokens_strip.dart').readAsStringSync();
    for (final symbol in ['layerSticky', 'layerModal', 'focusRingWidth']) {
      expect(strip, contains(symbol), reason: 'TokensStrip.$symbol ausente');
    }
  });

  test('TokensStrip defines typography scale and elevation', () {
    final strip = File('lib/core/theme/tokens_strip.dart').readAsStringSync();
    for (final step in ['fontH1', 'fontH2', 'fontBody', 'fontBodySm']) {
      expect(strip, contains(step), reason: 'TokensStrip.$step ausente');
    }
    expect(strip, contains('elevation('));
  });

  test('hub screens use hierarchy tokens or focus patterns', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final usesHierarchy = source.contains('shell_chrome.dart') ||
          source.contains('FocuxHubTypography') ||
          source.contains('FocuxTypography') ||
          source.contains('TokensStrip.h1') ||
          source.contains('TokensStrip.h2') ||
          source.contains('TokensStrip.fontH') ||
          source.contains('dashboard_day_focus') ||
          source.contains('dashboard_readability') ||
          source.contains('aluno_360_layout') ||
          source.contains('DashboardLayout') ||
          source.contains('operacaoFocus') ||
          source.contains('operacao_focus') ||
          source.contains('FxSettingsLayout') ||
          source.contains('AppTypography') ||
          source.contains('textTheme.headline') ||
          source.contains('textTheme.display');
      expect(
        usesHierarchy,
        isTrue,
        reason: '$path deve usar tokens de hierarquia ou foco',
      );
    }
  });

  test('personal dashboard exposes day focus banner', () {
    // Banner de foco vive nos slivers extraídos da Home.
    final source =
        readScreenSourceBundle(
          'lib/features/dashboard/screens/personal_dashboard_screen.dart',
        ) +
        File(
          'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
        ).readAsStringSync();
    expect(source, contains('DashboardDayFocusBanner'));
    expect(source, contains('dashboard_day_focus.dart'));
  });

  test('aluno detail exposes operacao focus mode', () {
    final source = readScreenSourceBundle(
      'lib/features/alunos/screens/aluno_detail_screen.dart',
    );
    expect(source, contains('alunoOperacaoFocusModeProvider'));
    expect(source, contains('aluno360_operacao_sticky_cta'));
  });
}
