import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard hoje usa microcopy, contraste e a11y 10/10', () {
    const paths = [
      'lib/features/dashboard/screens/personal_dashboard_screen.dart',
      'lib/features/dashboard/utils/dashboard_screen_helpers.dart',
      'lib/features/dashboard/widgets/dashboard_horizontal_scroll_peek.dart',
      'lib/features/dashboard/widgets/dashboard_pulse_strip.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section.dart',
      'lib/features/dashboard/widgets/dashboard_command_center_section_actions.part.dart',
      'lib/features/dashboard/widgets/dashboard_tools_section.dart',
      'lib/features/dashboard/widgets/dashboard_financial_hero_section.dart',
      'lib/features/dashboard/widgets/dashboard_shimmer_loading.dart',
    ];
    final screen = paths.map((p) => File(p).readAsStringSync()).join('\n');

    expect(screen, contains('dashboardSectionKickerStyle'));
    expect(screen, contains("'Panorama financeiro'"));
    expect(screen, contains("'Pulso operacional'"));
    expect(screen, contains("'Impacto hoje'"));
    expect(screen, contains('financeInadimplLabel'));
    expect(screen, contains('financePercentLabel'));
    expect(screen, contains('Meta batida'));
    expect(screen, contains('pulseCheckinsAccent'));
    expect(screen, contains('DashboardHorizontalScrollPeek'));
    expect(screen, contains('Deslize horizontalmente para ver mais'));
    expect(screen, contains("label: 'Pendente'"));
    expect(screen, contains("label: 'Ticket médio'"));
    expect(screen, contains('excessBeyondMeta'));
    expect(screen, contains('BrandPalette.sectionLink'));
    expect(screen, contains('nextActions.length > 1'));
    expect(screen, contains('dashboardCollapsibleSemanticsLabel'));
    expect(screen, contains('dashboard_entry_motion.dart'));
    expect(screen, contains('DashboardDayFocusBanner'));
    expect(screen, contains('groupDashboardToolShortcuts'));
    expect(screen, contains('Buscar ferramenta'));
    expect(screen, contains('dashboardReadableMuted'));
    expect(screen, contains('Abrir financeiro'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(10));
  });
}
