import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
      'lib/features/dashboard/widgets/dashboard_financial_hero_section.dart',
      'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/utils/dashboard_next_actions.dart',
      'lib/features/dashboard/utils/dashboard_home_focus.dart',
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
    expect(screen, contains("label: 'Pendente'"));
    expect(screen, contains("label: 'Ticket médio'"));
    expect(screen, contains('_showTicketMedio'));
    expect(screen, contains('excessBeyondMeta'));
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
    expect(screen, contains('Abrir financeiro'));
    expect(screen, contains('_compactZeroRevenue'));
    expect(screen, contains('backgroundColor: Colors.white'));
    expect(screen, contains('maxVisibleNextActions'));
    expect(screen, contains('modoFoco'));
    final shortcutsFile = File(
      'lib/features/dashboard/data/dashboard_tool_shortcuts.dart',
    ).readAsStringSync();
    expect(shortcutsFile, isNot(contains('roiQuickLinks')));
    expect(shortcutsFile, contains("label: 'Preços'"));
    expect(shortcutsFile, contains("label: 'Marca própria'"));
    expect(screen, isNot(contains('retornoRapido')));
    expect(screen, isNot(contains('DashboardRoiQuickLinksRow')));
    expect(screen, contains('DashboardMicrocopy.commandCenterTitle'));
    expect(screen, contains('featuredTools'));
    expect(screen, contains('verCatalogoCompleto'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(10));
  });
}
