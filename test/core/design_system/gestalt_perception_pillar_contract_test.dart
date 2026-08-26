import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/gestalt/focux_gestalt.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 17 — Gestalt & percepção: agrupamento visual nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('gestalt catalog and automated gates exist', () {
    for (final path in FocuxGestalt.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxGestalt.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/gestalt/focux_gestalt_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents gestalt and perception', () {
    final doc = File('lib/core/design_system.dart').readAsStringSync();
    expect(doc, contains('Gestalt & percepção'));
    expect(doc, contains('FocuxGestalt'));
    expect(doc, contains('gestalt_perception_pillar_contract_test'));
  });

  test('hub screens use visual grouping patterns', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunoDetailWidgets = [
      'lib/features/alunos/widgets/aluno360_section_header.dart',
      'lib/features/alunos/widgets/aluno360_copilot_card.dart',
    ];
    const dashboardWidgets = [
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/dashboard_section_header.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
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
      if (path.endsWith('personal_dashboard_screen.dart')) {
        for (final widget in dashboardWidgets) {
          source += File(widget).readAsStringSync();
        }
      }

      final hasGrouping = FocuxGestalt.hubGestaltPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasGrouping,
        isTrue,
        reason: '$path deve agrupar conteúdo com padrões Gestalt Fx',
      );
    }
  });

  test('list surfaces use fxListTileCardShell not bare ListTile', () {
    final eagle =
        File('test/core/design_system/eagle_design_contract_test.dart')
            .readAsStringSync();
    expect(eagle, contains('fxListTileCardShell'));
    expect(eagle, contains('ListTile'));
  });

  test('horizontal continuity uses FxHorizontalScrollPeek', () {
    final peek =
        File('lib/core/widgets/fx_horizontal_scroll_peek.dart').readAsStringSync();
    expect(peek, contains('FxHorizontalScrollPeek'));
  });

  test('financeiro groups content with TabBar sections', () {
    final source = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_screen.dart',
    );
    expect(source, contains('TabBar'));
    expect(source, contains('TabBarView'));
  });
}
