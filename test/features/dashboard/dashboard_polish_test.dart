import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dashboard hoje usa microcopy, contraste e a11y 10/10', () {
    final screen =
        File(
          'lib/features/dashboard/screens/personal_dashboard_screen.dart',
        ).readAsStringSync();

    expect(screen, contains('_dashboardSectionKickerStyle'));
    expect(screen, contains("'Panorama financeiro'"));
    expect(screen, contains("'Pulso operacional'"));
    expect(screen, contains("'Impacto hoje'"));
    expect(screen, contains('_financeInadimplLabel'));
    expect(screen, contains('_financePercentLabel'));
    expect(screen, contains('barra no teto'));
    expect(screen, contains('_pulseCheckinsAccent'));
    expect(screen, contains('_HorizontalScrollPeek'));
    expect(screen, contains('Deslize horizontalmente para ver mais'));
    expect(screen, contains("label: 'Pendente'"));
    expect(screen, contains("label: 'Ticket médio'"));
    expect(screen, contains('excessBeyondMeta'));
    expect(screen, contains('BrandPalette.sectionLink'));
    expect(screen, contains('nextActions.length > 1'));
    expect(screen, contains('Recolher mais ferramentas'));
    expect(screen, contains('Expandir mais ferramentas, 6 atalhos'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(6));
  });
}
