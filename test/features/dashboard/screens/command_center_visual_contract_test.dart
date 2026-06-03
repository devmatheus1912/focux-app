import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('command center autonomy bottlenecks keep compact layout safe', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_sticky_header.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section_actions.part.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_aderencia_semana_widget.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
    ];
    final widget = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(widget, contains('class DashboardCommandCenterSection'));
    expect(widget, contains('commandCenterProvider'));
    expect(widget, contains('chatInboxProvider'));
    expect(widget, contains("'Central de Comando'"));
    expect(widget, contains('A melhor próxima ação'));
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
    expect(widget, contains('Pulso operacional'));
    expect(widget, contains('BoxConstraints(minHeight: 48)'));
    expect(widget, contains('hideRiscoChip'));
    expect(widget, contains("collapsedActionLabel: 'Revisar'"));
    expect(widget, contains('collapsedPreview: attentionCollapsedPreview'));
    expect(widget, contains('trailingActionLabel: stickyCommandActionsLabel'));
    expect(widget, contains('DashboardCommandCenterStickyHeaderDelegate'));
    expect(widget, contains('SliverPersistentHeader'));
    expect(widget, contains('Agendar primeiro treino'));
    expect(widget, isNot(contains('Abrir agenda do dia')));
    expect(widget, contains('buildDashboardNextActions'));
    expect(widget, isNot(contains('_RiskWaveBanner')));
    expect(widget, contains('DashboardAderenciaSemanaEmptyCard'));
    expect(widget, contains('isRiskEchoCopy'));
    expect(widget, contains('BrandPalette.sectionHeading'));
    expect(widget, contains('BrandPalette.sectionAction'));
  });
}
