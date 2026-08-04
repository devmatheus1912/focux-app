import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command center autonomy bottlenecks keep compact layout safe', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/screens/personal_dashboard_screen_build.part.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_sticky_header.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section_actions.part.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_aderencia_semana_widget.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
      'lib/features/dashboard/widgets/dashboard_tools_section.dart',
      'lib/features/dashboard/utils/dashboard_tool_recent_store.dart',
      'lib/features/dashboard/utils/dashboard_scroll_logic.dart',
      'lib/features/dashboard/utils/dashboard_microcopy.dart',
      'lib/features/dashboard/utils/dashboard_next_actions.dart',
      'lib/features/dashboard/utils/dashboard_home_focus.dart',
    ];
    final widget = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(widget, contains('class DashboardCommandCenterSection'));
    expect(widget, contains('commandCenterProvider'));
    expect(widget, contains('chatInboxProvider'));
    expect(widget, contains('commandCenterTitle'));
    expect(widget, contains('class CommandActionPanel'));
    expect(widget, contains('class CommandActionTile'));
    expect(widget, contains('showCommandActionsSheet'));
    expect(widget, contains("PageStorageKey('personal-command-modules')"));
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
    expect(widget, contains('trailingActionLabel: stickyCommandActionsLabel'));
    expect(widget, contains('verPrioridades'));
    expect(widget, contains('showPrioritiesAction: showStickyPrioritiesAction'));
    expect(widget, contains('_homeScrollOffset >= 80'));
    expect(widget, contains('dashboardShowsFloatingPrioritiesChip'));
    expect(widget, contains('dashboardScrollOffsetMeaningfullyChanged'));
    expect(widget, contains('DashboardToolRecentStore'));
    expect(widget, contains('recentes'));
    expect(widget, contains('prioritiesActionLabel'));
    expect(widget, contains('showPrioritiesLink'));
    expect(widget, contains('CommandPrioritiesSheet'));
    expect(widget, contains('Ações por aluno'));
    expect(widget, contains('isRadarStudent'));
    expect(widget, contains('priorityBadge'));
    expect(widget, contains('BILLING_PENDING'));
    expect(widget, contains('dashboardFormatCountCopy'));
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
  });
}
