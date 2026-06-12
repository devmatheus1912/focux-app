import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/density/focux_density.dart';

import '../../support/screen_source_bundle.dart';

/// Pilar 18 — Densidade de informação: truncamento, compactação e disclosure nos hubs.
void main() {
  const hubScreens = [
    'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    'lib/features/alunos/screens/aluno_detail_screen.dart',
    'lib/features/alunos/screens/alunos_list_screen.dart',
    'lib/features/treinos/screens/treinos_list_screen.dart',
    'lib/features/financeiro/screens/financeiro_screen.dart',
    'lib/features/ia/screens/ia_copiloto_screen.dart',
  ];

  test('density catalog and automated gates exist', () {
    for (final path in FocuxDensity.coreSources) {
      expect(File(path).existsSync(), isTrue, reason: 'Fonte ausente: $path');
    }
    for (final path in FocuxDensity.automatedGates) {
      expect(File(path).existsSync(), isTrue, reason: 'Gate ausente: $path');
    }
    expect(
      File('test/core/density/focux_density_test.dart').existsSync(),
      isTrue,
    );
  });

  test('DESIGN_SYSTEM documents information density', () {
    final doc = File('docs/DESIGN_SYSTEM.md').readAsStringSync();
    expect(doc, contains('Densidade de informação'));
    expect(doc, contains('FocuxDensity'));
    expect(doc, contains('information_density_pillar_contract_test'));
  });

  test('hub screens manage information density', () {
    const alunosStatePart =
        'lib/features/alunos/screens/alunos_list_screen_state.part.dart';
    const financeiroTabs = [
      'lib/features/financeiro/screens/financeiro_mensalidades_tab.dart',
      'lib/features/financeiro/screens/financeiro_mensalidades_tab_actions.part.dart',
    ];
    const iaParts = [
      'lib/features/ia/screens/ia_copiloto_screen_actions.part.dart',
      'lib/features/ia/widgets/ia_expandable_copy.dart',
    ];

    for (final path in hubScreens) {
      expect(File(path).existsSync(), isTrue, reason: 'Hub ausente: $path');
      var source = readScreenSourceBundle(path);

      if (path.endsWith('alunos_list_screen.dart')) {
        source += File(alunosStatePart).readAsStringSync();
      }
      if (path.endsWith('financeiro_screen.dart')) {
        for (final tab in financeiroTabs) {
          source += File(tab).readAsStringSync();
        }
      }
      if (path.endsWith('ia_copiloto_screen.dart')) {
        for (final part in iaParts) {
          source += File(part).readAsStringSync();
        }
      }

      final managesDensity = FocuxDensity.hubDensityPatterns
          .any((pattern) => source.contains(pattern));
      expect(
        managesDensity,
        isTrue,
        reason: '$path deve truncar, compactar ou colapsar conteúdo',
      );
    }
  });

  test('global theme sets compact visual density baseline', () {
    final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
    expect(theme, contains('VisualDensity.compact'));
  });

  test('dashboard uses collapsible sections for progressive disclosure', () {
    final dashboard = readScreenSourceBundle(
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
    );
    expect(dashboard, contains('DashboardCollapsibleSection'));
    expect(dashboard, contains('collapsedHint'));
    expect(dashboard, contains('maxLines'));
  });

  test('alunos list exposes user-controlled compact density', () {
    final source = readScreenSourceBundle(
      'lib/features/alunos/screens/alunos_list_screen.dart',
    ) +
        File('lib/features/alunos/screens/alunos_list_screen_state.part.dart')
            .readAsStringSync();
    expect(source, contains('AlunoListPreferences'));
    expect(source, contains('Lista compacta'));
    expect(source, contains('compact:'));
  });

  test('module layouts define spacing tokens that bound density', () {
    final dashboard =
        File('lib/features/dashboard/constants/dashboard_layout.dart')
            .readAsStringSync();
    expect(dashboard, contains('sectionGap'));

    final aluno360 =
        File('lib/features/alunos/constants/aluno_360_layout.dart')
            .readAsStringSync();
    expect(aluno360, contains('sectionGap'));
    expect(aluno360, contains('compactContactPriority'));
  });
}
