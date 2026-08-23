import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pilar 3 — Lógica de negócio: hubs delegam para utils/parts dedicados.
void main() {
  const hubScreens = {
    'lib/features/dashboard/screens/personal_dashboard_screen.dart': [
      'dashboard_scroll_logic.dart',
      'dashboard_onboarding_logic.dart',
    ],
    'lib/features/alunos/screens/aluno_detail_screen.dart': [
      'aluno360_operacao_logic.dart',
      'aluno360_copilot_logic.dart',
    ],
    'lib/features/alunos/screens/alunos_list_screen.dart': [
      'aluno_list_card.dart',
      "part 'alunos_list_screen_state.part.dart'",
    ],
    'lib/features/treinos/screens/treinos_list_screen.dart': [
      'treinos_list_labels.dart',
      "part 'treinos_list_screen_state.part.dart'",
    ],
    'lib/features/financeiro/screens/financeiro_screen.dart': [
      'financeiro_mensalidades_tab.dart',
    ],
    'lib/features/ia/screens/ia_copiloto_screen.dart': [
      "part 'ia_copiloto_screen_actions.part.dart'",
    ],
  };

  const requiredLogicFiles = [
    'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
    'lib/features/dashboard/utils/dashboard_onboarding_logic.dart',
    'lib/features/alunos/utils/aluno360_operacao_logic.dart',
    'lib/features/alunos/utils/aluno360_copilot_logic.dart',
    'lib/features/alunos/utils/alunos_list_sparkline_logic.dart',
    'lib/features/treinos/utils/treinos_list_labels.dart',
    'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
    'lib/features/treinos/screens/treinos_list_screen_state.part.dart',
    'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
  ];

  test('hub screens import dedicated logic utils or parts', () {
    for (final entry in hubScreens.entries) {
      final screen = File(entry.key).readAsStringSync();
      for (final marker in entry.value) {
        expect(
          screen,
          contains(marker),
          reason: '${entry.key} deve referenciar $marker',
        );
      }
    }

    // Sparkline delegada ao card compartilhado, que usa a logic pura.
    final alunoCard = File(
      'lib/features/alunos/widgets/aluno_list_card.dart',
    ).readAsStringSync();
    expect(alunoCard, contains('alunos_list_sparkline_logic.dart'));
  });

  test('required business logic modules exist', () {
    for (final path in requiredLogicFiles) {
      expect(File(path).existsSync(), isTrue, reason: 'Módulo ausente: $path');
    }
  });

  test('personal dashboard does not embed scroll threshold literals', () {
    final screen = File(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    ).readAsStringSync();
    expect(screen, isNot(contains('_commandCenterPrioritiesFloatingMaxOffset')));
    expect(screen, isNot(contains('_showsFloatingPrioritiesChip')));
    expect(screen, contains('dashboard_scroll_logic.dart'));
    expect(screen, contains('dashboard_onboarding_logic.dart'));
  });

  test('treinos list hub is decomposed under 100 LOC entry file', () {
    final lines = File(
      'lib/features/treinos/screens/treinos_list_screen.dart',
    ).readAsLinesSync().length;
    expect(lines, lessThan(100));
    final screen = File(
      'lib/features/treinos/screens/treinos_list_screen.dart',
    ).readAsStringSync();
    expect(screen, contains("part 'treinos_list_screen_state.part.dart'"));
  });
}
