import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pilar 3 — Lógica de negócio: hubs e controllers tier-1 delegam para services/utils.
void main() {
  const hubScreens = {
    'lib/features/dashboard/screens/personal_dashboard_screen.dart':
        'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart':
        'lib/features/alunos/utils/aluno360_operacao_logic.dart',
  };

  const requiredLogicFiles = [
    'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
    'lib/features/dashboard/utils/dashboard_onboarding_logic.dart',
    'lib/features/alunos/utils/aluno360_operacao_logic.dart',
    'lib/features/alunos/utils/aluno360_copilot_logic.dart',
  ];

  test('hub screens import dedicated logic utils', () {
    for (final entry in hubScreens.entries) {
      final screen = File(entry.key).readAsStringSync();
      final logicPath = entry.value;
      expect(File(logicPath).existsSync(), isTrue, reason: 'Logic ausente: $logicPath');
      final logicFile = logicPath.split('/').last;
      expect(
        screen,
        contains(logicFile),
        reason: '${entry.key} deve importar $logicFile',
      );
    }
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
}
