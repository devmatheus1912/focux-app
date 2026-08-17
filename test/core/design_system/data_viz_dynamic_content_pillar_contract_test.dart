import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/data_viz/focux_data_viz.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 20 — Data viz & conteúdo dinâmico: séries e async nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('data viz catalog and automated gates exist', () {
    for (final path in FocuxDataViz.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxDataViz.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/data_viz/focux_data_viz_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents data viz and dynamic content', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Data viz & conteúdo dinâmico'));
    expect(doc, contains('FocuxDataViz'));
    expect(doc, contains('data_viz_dynamic_content_pillar_contract_test'));
  });

  test('hub screens render charts or async dynamic content', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const alunoDetailWidgets = [
      'lib/features/alunos/widgets/aluno360_evolucao_inteligente_card.dart',
    ];
    const dashboardWidgets = [
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_financial_hero_section.dart',
    ];
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
      'lib/features/financeiro/screens/financeiro_resumo_screen.dart',
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
        source += File('lib/features/dashboard/utils/dashboard_sparkline_helpers.dart')
            .readAsStringSync();
      }
      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }

      final hasViz = FocuxDataViz.hubDataVizPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        hasViz,
        isTrue,
        reason: '$path deve ter sparkline/gráfico ou conteúdo async (.when)',
      );
    }
  });

  test('sparkline series are derived in utils not inline in widgets', () {
    final dashboardHelpers =
        File('lib/features/dashboard/utils/dashboard_sparkline_helpers.dart')
            .readAsStringSync();
    expect(dashboardHelpers, contains('List<double>'));

    final alunoLogic =
        File('lib/features/alunos/utils/aluno360_evolucao_inteligente_logic.dart')
            .readAsStringSync();
    expect(alunoLogic, contains('resolveVolumeSparklineData'));
  });

  test('financeiro hub exposes bar and donut charts', () {
    final dashboard = readScreenSourceBundle(
      'lib/features/financeiro/screens/financeiro_dashboard_screen.dart',
    );
    expect(dashboard, contains('_EvolucaoChart'));

    final resumo =
        File('lib/features/financeiro/screens/financeiro_resumo_screen.dart')
            .readAsStringSync();
    expect(resumo, contains('PieChart'));
  });

  test('ia hub loads insights with async when', () {
    final ia = readScreenSourceBundle(
      'lib/features/ia/screens/ia_copiloto_screen.dart',
    );
    expect(ia, contains('iaCopilotoHomeProvider'));
    expect(ia, contains('insightsProvider'));
    expect(ia, contains('.when('));
  });
}
