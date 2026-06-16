import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/refactoring/focux_refactoring.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 22 — Refatoração robusta: decomposição de hubs e lógica extraída.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('refactoring catalog and automated gates exist', () {
    for (final path in FocuxRefactoring.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxRefactoring.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/refactoring/focux_refactoring_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents robust refactoring', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Refatoração robusta'));
    expect(doc, contains('FocuxRefactoring'));
    expect(doc, contains('robust_refactoring_pillar_contract_test'));
  });

  test('hub screens delegate to module utils widgets or parts', () {
    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      final source = readScreenSourceBundle(path);
      final marker = FocuxRefactoring.hubDecompositionMarkers[path];
      expect(marker, isNotNull, reason: 'Módulo não mapeado: $path');

      final usesModuleLayer = source.contains(marker!) ||
          FocuxRefactoring.hubRefactoringPatterns
              .any((pattern) => source.contains(pattern));
      expect(
        usesModuleLayer,
        isTrue,
        reason: '$path deve importar utils/widgets/parts do módulo',
      );
    }
  });

  test('large hub screens use part decomposition', () {
    for (final path in hubScreens) {
      final lineCount = File(path).readAsLinesSync().length;
      if (!FocuxRefactoring.requiresDecomposition(lineCount)) continue;

      final main = File(path).readAsStringSync();
      final marker = FocuxRefactoring.hubDecompositionMarkers[path];
      final moduleUtils = RegExp(r'(features/[^/]+/utils/|\.\./utils/)');
      final decomposed = main.contains("part '") ||
          (marker != null && main.contains(marker)) ||
          moduleUtils.hasMatch(main);
      expect(
        decomposed,
        isTrue,
        reason: '$path ($lineCount LOC) deve usar part ou utils extraídos',
      );
    }
  });

  test('personal dashboard keeps scroll logic outside build', () {
    final screen = File(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('dashboard_scroll_logic.dart'));
    expect(screen, isNot(contains('_commandCenterPrioritiesFloatingMaxOffset')));
  });

  test('aluno detail imports operacao and copilot logic utils', () {
    final screen = File(
      'lib/features/alunos/screens/aluno_detail_screen.dart',
    ).readAsStringSync();
    expect(screen, contains('aluno360_operacao_logic.dart'));
    expect(screen, contains('aluno360_copilot_logic.dart'));
  });

  test('add exercicio entry file stays decomposed under 100 LOC', () {
    final lines = File(
      'lib/features/exercicios/screens/add_exercicio_screen.dart',
    ).readAsLinesSync().length;
    expect(lines, lessThan(100));
    final screen = File(
      'lib/features/exercicios/screens/add_exercicio_screen.dart',
    ).readAsStringSync();
    expect(screen, contains("part 'add_exercicio_screen_state.part.dart'"));
  });

  test('perfil aluno entry file stays decomposed under 100 LOC', () {
    final lines = File(
      'lib/features/dashboard/screens/perfil_aluno_screen.dart',
    ).readAsLinesSync().length;
    expect(lines, lessThan(100));
    final screen = File(
      'lib/features/dashboard/screens/perfil_aluno_screen.dart',
    ).readAsStringSync();
    expect(screen, contains("part 'perfil_aluno_screen_state.part.dart'"));
  });
}
