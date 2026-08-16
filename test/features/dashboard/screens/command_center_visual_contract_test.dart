import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command center autonomy bottlenecks keep compact layout safe', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_state.part.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/dashboard_home_primary_slivers.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_sticky_header.dart',
      'lib/features/dashboard/widgets/command_action_panel.dart',
      'lib/features/dashboard/widgets/command_action_tile.dart',
      'lib/features/dashboard/widgets/command_priorities_sheet.dart',
      'lib/features/dashboard/widgets/command_status_tile.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_aderencia_semana_widget.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
      'lib/features/dashboard/widgets/dashboard_tools_section.dart',
      'lib/features/dashboard/widgets/dashboard_tools_catalog_sheet.dart',
      'lib/features/dashboard/utils/dashboard_tool_recent_store.dart',
      'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/utils/dashboard_next_actions.dart',
      'lib/features/dashboard/utils/dashboard_command_copy.dart',
      'lib/features/dashboard/utils/dashboard_home_focus.dart',
      'lib/features/dashboard/widgets/dashboard_home_header.dart',
      'lib/features/dashboard/widgets/dashboard_attention_rail.dart',
      'lib/features/dashboard/utils/dashboard_home_snapshot.dart',
      'lib/features/dashboard/data/dashboard_repository.dart',
      'lib/features/dashboard/data/dashboard_tool_shortcuts.dart',
      'lib/features/dashboard/utils/dashboard_chat_subtitle.dart',
      'lib/features/dashboard/utils/dashboard_unread.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
    ];
    final widget = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(widget, contains('class DashboardCommandCenterSection'));
    expect(widget, contains('commandCenterProvider'));
    expect(widget, contains('commandCenterTitle'));
    expect(widget, contains('class CommandActionPanel'));
    expect(widget, contains('class CommandActionTile'));
    expect(widget, contains('showCommandActionsSheet'));
    expect(widget, contains('_MessagesShortcutRow'));
    expect(widget, contains('atalhoKicker'));
    expect(widget, contains('if (hasTrend)'));
    expect(widget, contains('snapSizes'));
    expect(widget, contains('scrollDirection: Axis.horizontal'));
    expect(widget, contains('Shimmer.fromColors'));
    expect(widget, contains('maxLines: 2'));
    expect(widget, contains('TextOverflow.ellipsis'));
    expect(widget, contains('class DashboardDayPulseStrip'));
    expect(widget, contains('class DashboardPulseChip'));
    expect(widget, contains('pulsoOperacional'));
    expect(widget, contains('BoxConstraints(minHeight: 48)'));
    expect(widget, contains('hideRiscoChip'));
    expect(widget, contains("collapsedActionLabel: 'Revisar'"));
    expect(widget, contains('class DashboardPrioritiesOverlay'));
    expect(widget, contains('dashboardPanelIsOffscreen'));
    expect(widget, contains('verPrioridades'));
    expect(widget, contains('dashboardShowsStickyPrioritiesAction'));
    expect(widget, contains('panelOffscreen'));
    expect(widget, contains('_commandPanelKey'));
    expect(widget, contains('DashboardPulseSnapshot'));
    expect(widget, contains('riskOwnedByDayFocus'));
    expect(widget, contains('featuredTools'));
    expect(widget, contains('showDashboardToolsCatalogSheet'));
    expect(widget, contains('checkinsTrend'));
    expect(widget, contains('attentionRiskLimit'));
    expect(widget, contains('dashboardChatShortcutSubtitle'));
    expect(widget, contains('dashboardChatUnreadCount'));
    expect(widget, contains('tendenciaVaziaChip'));
    expect(widget, contains('dashboardPulseEmptyHint'));
    expect(widget, contains('pulseAgendaAccent'));
    expect(widget, contains('dashboardShowsInlinePrioritiesLink'));
    expect(widget, contains('mensagensNaoLidas'));
    expect(widget, contains('notificacoesNaoLidas'));
    expect(widget, contains('dashboardScrollOffsetMeaningfullyChanged'));
    expect(widget, contains('dashboardScrollVisualStateChanged'));
    expect(widget, isNot(contains('DashboardMicrocopy.recentes')));
    expect(
      widget,
      isNot(
        contains('dashboardShowsFloatingPrioritiesChip(_homeScrollOffset)'),
      ),
    );
    expect(widget, isNot(contains('inboxUnread: 0')));
    expect(widget, isNot(contains('inboxReady: false')));
    expect(widget, isNot(contains('DashboardDayFocus.resolve(')));
    expect(widget, contains('prioritiesActionLabel'));
    expect(widget, contains('showPrioritiesLink'));
    expect(widget, contains('CommandPrioritiesSheet'));
    expect(widget, contains('Ações por aluno'));
    expect(widget, contains('isRadarStudent'));
    expect(widget, contains('priorityBadge'));
    expect(widget, contains('BILLING_PENDING'));
    expect(widget, contains('dashboardFormatCountCopy'));
    expect(widget, contains('dashboardClampActionCopy'));
    expect(widget, contains('useRootNavigator: true'));
    expect(widget, contains('DraggableScrollableSheet'));
    expect(widget, contains('maisPrioridades'));
    expect(widget, contains('hasRiskCurated'));
    expect(widget, contains('dashboardPriorityBadgeColors'));
    expect(widget, contains('DashboardCommandCenterStickyHeaderDelegate'));
    expect(widget, contains('SliverPersistentHeader'));
    expect(widget, contains('Agendar primeiro treino'));
    expect(widget, isNot(contains('Abrir agenda do dia')));
    expect(widget, contains('buildDashboardNextActions'));
    expect(widget, contains('DashboardHomeFocusRules'));
    expect(widget, contains('DashboardAderenciaCopy'));
    expect(widget, isNot(contains('_RiskWaveBanner')));
    expect(widget, contains('DashboardAderenciaSemanaEmptyCard'));
    expect(widget, contains('isRiskEchoCopy'));
    expect(widget, contains('BrandPalette.sectionHeading'));
    expect(widget, contains('BrandPalette.sectionAction'));

    // Central de Comando é apresentacional — a fila é computada uma vez só.
    expect(widget, contains('required this.nextActions'));
    expect(widget, contains('required this.prioritiesSheetActions'));
    expect(widget, contains('required this.showPrioritiesLink'));
    expect(widget, contains('final nextActions = widget.nextActions'));
    expect(widget, contains('riskOwnedByDayFocus'));
  });
}
