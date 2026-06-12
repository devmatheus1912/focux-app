import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/clean_code/focux_clean_code.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 23 — Código limpo & escalável: tipos explícitos e composição nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('clean code catalog and automated gates exist', () {
    for (final path in FocuxCleanCode.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxCleanCode.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/clean_code/focux_clean_code_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents clean scalable code', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Código limpo'));
    expect(doc, contains('FocuxCleanCode'));
    expect(doc, contains('clean_scalable_code_pillar_contract_test'));
  });

  test('hub screens compose design tokens and avoid raw maps', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);

      final composed = FocuxCleanCode.hubCompositionPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        composed,
        isTrue,
        reason: '$path deve compor tokens/layout do design system',
      );

      for (final forbidden in FocuxCleanCode.forbiddenHubPatterns) {
        expect(
          source.contains(forbidden),
          isFalse,
          reason: '$path não deve conter: $forbidden',
        );
      }
    }
  });

  test('ia copilot uses typed proxima acao model', () {
    final screen = File(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    ).readAsStringSync();
    final provider = File(
      'lib/features/ia/providers/ia_copilot_providers.dart',
    ).readAsStringSync();
    expect(screen, contains('IaCopilotProximaAcao'));
    expect(provider, contains('IaCopilotProximaAcao'));
    expect(screen, isNot(contains('Map<String, dynamic>? _proximaAcao')));
  });

  test('alunos list sparkline logic is extracted', () {
    final screen = File(
      'lib/features/alunos/screens/alunos_list_screen.dart',
    ).readAsStringSync();
    final cards = File(
      'lib/features/alunos/screens/alunos_list_screen_cards.part.dart',
    ).readAsStringSync();
    expect(screen, contains('alunos_list_sparkline_logic.dart'));
    expect(cards, contains('alunosListSparklineMetrics'));
    expect(cards, isNot(contains('List<Map<String, dynamic>>')));
  });

  test('coding standards document clean code principles', () {
    final doc = File('docs/CODING_STANDARDS.md').readAsStringSync();
    expect(doc, contains('Lógica fora da UI'));
    expect(doc, contains('Tipos explícitos'));
  });
}
