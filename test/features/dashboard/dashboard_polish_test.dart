import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard feature não usa fontSize 18/19/20/22 soltos', () {
    final root = Directory('lib/features/dashboard');
    final forbidden = RegExp(r'fontSize:\s*(18|19|20|22)\b');
    final offenders = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (forbidden.hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}:${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use FocuxHubTypography (pageTitle/sectionTitle/metricEm/metricLg). '
          'Offenders:\n${offenders.join('\n')}',
    );
  });

  test('dashboard feature não usa AppTypography.inter ad-hoc', () {
    final root = Directory('lib/features/dashboard');
    final offenders = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final text = entity.readAsStringSync();
      if (text.contains('AppTypography.inter')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('dashboard hoje usa microcopy, contraste e a11y', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
      'lib/features/dashboard/widgets/dashboard_horizontal_scroll_peek.dart',
      'lib/core/widgets/fx_horizontal_scroll_peek.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/command_action_panel.dart',
      'lib/features/dashboard/widgets/command_action_tile.dart',
      'lib/features/dashboard/widgets/command_priorities_sheet.dart',
      'lib/features/dashboard/widgets/command_status_tile.dart',
      'lib/features/dashboard/widgets/dashboard_tools_section.dart',
      'lib/features/dashboard/widgets/dashboard_tools_catalog_sheet.dart',
      'lib/features/dashboard/widgets/dashboard_financial_hero_section.dart',
      'lib/features/dashboard/widgets/dashboard_finance_empty.dart',
      'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
      'lib/features/dashboard/widgets/dashboard_home_secondary_block.dart',
      'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
      'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/utils/dashboard_next_actions.dart',
      'lib/features/dashboard/utils/dashboard_home_focus.dart',
      'lib/features/dashboard/widgets/dashboard_home_header.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_sticky_header.dart',
      'lib/features/dashboard/widgets/dashboard_attention_rail.dart',
      'lib/features/dashboard/widgets/dashboard_collapsible_section.dart',
      'lib/features/dashboard/utils/dashboard_a11y.dart',
      'lib/features/dashboard/utils/dashboard_home_snapshot.dart',
    ];
    final screen = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(screen, contains('dashboardSectionKickerStyle'));
    expect(screen, contains('panoramaFinanceiro'));
    expect(screen, contains('receitaAtual > 0'));
    expect(screen, contains(r'R\$ 0 recebido · meta do mês'));
    expect(screen, contains('pulsoOperacional'));
    expect(screen, contains('impactoHoje'));
    expect(screen, contains('financeInadimplLabel'));
    expect(screen, contains('financePercentLabel'));
    expect(screen, contains('Meta batida'));
    expect(screen, contains('pulseCheckinsAccent'));
    expect(screen, contains('DashboardHorizontalScrollPeek'));
    expect(screen, contains('scrollPeekHint'));
    expect(screen, contains('Pendente'));
    expect(screen, contains('Ticket médio'));
    expect(screen, contains('_showTicketMedio'));
    expect(screen, contains('DashboardHomeActionChip'));
    expect(screen, contains('BrandPalette.sectionLink'));
    expect(screen, contains('showPrioritiesLink'));
    expect(screen, contains('verPrioridades'));
    expect(screen, contains('CommandPrioritiesSheet'));
    expect(screen, contains('Ações por aluno'));
    expect(screen, contains('dashboardCollapsibleSemanticsLabel'));
    expect(screen, contains('dashboard_entry_motion.dart'));
    expect(screen, contains('DashboardDayFocusBanner'));
    expect(screen, contains('DashboardHomeFocusRules'));
    expect(screen, contains('groupDashboardToolShortcuts'));
    expect(screen, contains('buscarFerramenta'));
    expect(screen, contains('dashboardReadableMuted'));
    expect(screen, contains('dashboardPriorityBadgeColors'));
    expect(screen, contains('dashboardPrioritiesChipForeground'));
    expect(screen, contains('RISK_STUDENTS'));
    expect(screen, contains('DashboardFinanceEmptyState'));
    // Sheet de prioridades migrou para o chrome canônico da Home (sem
    // DraggableScrollableSheet ad-hoc com snapSizes soltos).
    expect(screen, contains('showFxHomeSheet'));
    expect(screen, isNot(contains('DraggableScrollableSheet(')));
    expect(screen, contains('maxVisibleNextActions'));
    expect(screen, contains('modoFoco'));
    final shortcutsFile =
        File(
          'lib/features/dashboard/data/dashboard_tool_shortcuts.dart',
        ).readAsStringSync();
    expect(shortcutsFile, isNot(contains('roiQuickLinks')));
    expect(shortcutsFile, isNot(contains("label: 'Preços'")));
    expect(shortcutsFile, contains("label: 'Marca própria'"));
    expect(screen, isNot(contains('retornoRapido')));
    expect(screen, isNot(contains('DashboardRoiQuickLinksRow')));
    expect(screen, contains('DashboardMicrocopy.commandCenterSubtitle'));
    expect(screen, contains('DashboardMicrocopy.verPrioridades'));
    expect(screen, contains('featuredTools'));
    expect(screen, contains('verCatalogoCompleto'));
    expect(screen, contains('omitSecondarySections'));
    expect(screen, contains('FxHelpIconButton'));
    expect(screen, isNot(contains('ShellThemeToggle')));
    expect(screen, contains('FxHelpChrome.iconSize'));
    expect(screen, contains('DashboardAttentionRail'));
    expect(screen, contains('checkinsPulseLabel'));
    expect(screen, contains('utilityOnly'));
    expect(screen, contains('hideEmptyTrend'));
    expect(screen, contains('FocuxHubTypography.sectionTitle'));
    expect(screen, contains('checkinsTrend'));
    expect(screen, contains('showDashboardToolsCatalogSheet'));
    expect(screen, contains('alunoFromAlertaResumo'));
    expect(screen, contains('if (onboardingFromHome != null)'));
    expect(screen, contains('statusFromHome: onboardingFromHome'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(10));
  });

  test('destaque da Home e catálogo são lista inset', () {
    final catalog = File(
      'lib/features/dashboard/widgets/dashboard_tools_catalog_sheet.dart',
    ).readAsStringSync();
    final tools = File(
      'lib/features/dashboard/widgets/dashboard_tools_section.dart',
    ).readAsStringSync();
    final group = File(
      'lib/features/dashboard/widgets/dashboard_tool_shortcut_group.dart',
    ).readAsStringSync();
    expect(catalog, contains('DashboardToolShortcutGroup'));
    expect(catalog, contains('ListView.builder'));
    expect(catalog, contains('catalogoSubtitle'));
    expect(catalog, isNot(contains('DashboardExpandableToolGroups')));
    expect(catalog, isNot(contains('shortcutAspectRatio')));
    expect(tools, contains('DashboardToolShortcutGroup'));
    expect(tools, contains('FxSettingsLayout.groupRadius'));
    expect(tools, isNot(contains('DashboardShortcutGrid')));
    expect(tools, isNot(contains('shortcutAspectRatio')));
    expect(tools, isNot(contains('AspectRatio')));
    expect(group, contains('FxSettingsTile'));
    expect(group, contains('FxSettingsGroup'));
    expect(group, contains('dashboardShortcutSemanticsLabel'));
    expect(group, contains('homeOverride: homePlanoFeatures'));
  });
}
