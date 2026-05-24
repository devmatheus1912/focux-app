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
    expect(screen, contains("label: 'Pendente'"));
    expect(screen, contains("label: 'Ticket médio'"));
    expect(screen, contains('percentLabel:'));
    expect(screen, contains('% da meta'));
    expect(screen, contains('BrandPalette.sectionLink'));
    expect(screen, contains('class _AttentionCard'));
    expect(screen, contains('class _CommandActionTile'));
    expect(screen, contains('Recolher mais ferramentas'));
    expect(screen, contains('Expandir mais ferramentas, 6 atalhos'));

    final semanticsCount = 'Semantics('.allMatches(screen).length;
    expect(semanticsCount, greaterThanOrEqualTo(6));
  });
}
