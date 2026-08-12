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
      expect(groups['Receita'], isNot(contains('Preços')));

      expect(
        groups['Crescimento'],
        containsAll(['Leads', 'Indique', 'Landing', 'Recuperação', 'Pesquisa NPS']),
      );

      expect(
        groups['Sistema'],
        containsAll([
          'Marca própria',
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

  group('DashboardToolShortcut.featuredTools', () {
    test('curates a slim, high-value subset for the default grid', () {
      final featured = DashboardToolShortcut.featuredTools;
      expect(featured, isNotEmpty);
      expect(featured.length, lessThanOrEqualTo(4));
      expect(featured.every((s) => s.featured), isTrue);
      expect(
        featured.toSet().length,
        featured.length,
        reason: 'no duplicate featured shortcuts',
      );
      for (final s in featured) {
        expect(DashboardToolShortcut.moreTools, contains(s));
      }
    });

    test('spans more than one group for a balanced default grid', () {
      final groups =
          DashboardToolShortcut.featuredTools.map((s) => s.group).toSet();
      expect(groups.length, greaterThan(1));
    });
  });

  group('duplicate icon fixes', () {
    test('Pacotes and Loja use distinct icons', () {
      final pacotes = DashboardToolShortcut.moreTools.firstWhere(
        (s) => s.label == 'Pacotes',
      );
      final loja = DashboardToolShortcut.moreTools.firstWhere(
        (s) => s.label == 'Loja',
      );
      expect(pacotes.icon, isNot(loja.icon));
    });

    test('Cobrança auto and Receita recorrente use distinct icons', () {
      final cobranca = DashboardToolShortcut.moreTools.firstWhere(
        (s) => s.label == 'Cobrança auto',
      );
      final receitaRecorrente = DashboardToolShortcut.moreTools.firstWhere(
        (s) => s.label == 'Receita recorrente',
      );
      expect(cobranca.icon, isNot(receitaRecorrente.icon));
    });
  });
}
