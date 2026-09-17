import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/brand/focux_branding.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 19 — Branding & personalidade: white-label e acento dinâmico nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  final hardcodedBrandHex = RegExp(
    r'Color\(0xFF0B4F5C\)|Color\(0xFF13C2C2\)|Color\(0xFF1EC8C8\)',
  );

  test('branding catalog and automated gates exist', () {
    for (final path in FocuxBranding.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxBranding.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/brand/focux_branding_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents branding and personality', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Branding & personalidade'));
    expect(doc, contains('FocuxBranding'));
    expect(doc, contains('branding_personality_pillar_contract_test'));
  });

  test('hub screens apply dynamic brand chrome', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunoDetailWidgets = [
      'lib/features/alunos/widgets/aluno_detail_hero_card.dart',
      'lib/features/alunos/widgets/aluno360_ferramentas_modules_grid.dart',
    ];
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
      }
      if (path.endsWith('aluno_detail_screen.dart')) {
        for (final widget in alunoDetailWidgets) {
          source += File(widget).readAsStringSync();
        }
      }
      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }

      final branded = FocuxBranding.hubBrandingPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        branded,
        isTrue,
        reason: '$path deve usar BrandPalette, ShellChrome ou primary do tema',
      );
    }
  });

  test('hub screens avoid hardcoded default brand hex', () {
    for (final path in hubScreens) {
      final source = readScreenSourceBundle(path);
      expect(
        hardcodedBrandHex.hasMatch(source),
        isFalse,
        reason: '$path não deve fixar hex da marca Focux',
      );
    }
  });

  test('brand copy is centralized in FocuxBrandCopy', () {
    final copy =
        File('lib/core/brand/focux_brand_copy.dart').readAsStringSync();
    expect(copy, contains('onboardingHook'));
    expect(copy, contains('FocuxMicrocopy'));

    final tagline =
        File('lib/core/widgets/focux_brand_tagline.dart').readAsStringSync();
    expect(tagline, contains('FocuxBrandCopy'));
  });

  test('theme derives palette from dynamic primary', () {
    final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(theme, contains('BrandPalette'));
    expect(theme, contains('primary'));
  });

  test('personal brand provider maps API identity fields', () {
    final provider =
        File('lib/core/providers/personal_brand_provider.dart').readAsStringSync();
    expect(provider, contains('corPrimaria'));
    expect(provider, contains('hideFocuxBranding'));
    expect(provider, contains('/api/aluno/personal-brand'));
  });
}
