import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_tool_groups.dart';

void main() {
  group('groupDashboardToolShortcuts', () {
    test('places known tools in intended buckets', () {
      final groups = {
        for (final g in groupDashboardToolShortcuts(
          DashboardToolShortcut.moreTools,
        ))
          g.title: g.shortcuts.map((s) => s.label).toSet(),
      };

      expect(groups['Operação'], containsAll(['Exercícios', 'Feed', 'Hábitos']));
      expect(groups['Operação'], isNot(contains('Receita recorrente')));
      expect(groups['Operação'], isNot(contains('Landing')));
      expect(groups['Operação'], isNot(contains('Configuração inicial')));

      expect(
        groups['Receita'],
        containsAll([
          'Receita recorrente',
          'Cobrança auto',
          'Recorrência',
          'Pacotes',
          'Ofertas',
        ]),
      );

      expect(
        groups['Crescimento'],
        containsAll(['Leads', 'Indique', 'Landing', 'Recuperação', 'Pesquisa NPS']),
      );

      expect(
        groups['Sistema'],
        containsAll([
          'Automações',
          'Equipe',
          'Configuração inicial',
          'Qualidade',
          'Broadcasts',
        ]),
      );
    });

    test('every moreTools shortcut has an explicit group', () {
      for (final s in DashboardToolShortcut.moreTools) {
        expect(s.group, isNotNull, reason: s.label);
      }
      expect(
        DashboardToolShortcut.moreTools.map((s) => s.label).toSet().length,
        DashboardToolShortcut.moreTools.length,
      );
    });
  });
}
