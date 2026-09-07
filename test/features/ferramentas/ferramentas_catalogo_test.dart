import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/ferramentas/utils/ferramentas_icons.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_tool_groups.dart';

import 'catalogo_fixture.dart';

void main() {
  late FerramentasCatalogo catalogo;

  setUp(() {
    catalogo = FerramentasCatalogo.fromJson(catalogoFixtureJson());
  });

  test('parse hubs ≤ 8 e unifica Captação/Vendas/Financeiro em abas', () {
    expect(catalogo.version, 3);
    expect(catalogo.hubs.length, lessThanOrEqualTo(8));
    expect(catalogo.hubs.map((h) => h.titulo), containsAll(['Captação', 'Vendas', 'Financeiro']));

    final captacao = catalogo.hubs.firstWhere((h) => h.id == 'captacao');
    expect(captacao.itens.single.isHubComAbas, isTrue);
    expect(captacao.itens.single.abas.map((a) => a.titulo), containsAll(['Lead Público', 'Landing']));

    final financeiro = catalogo.hubs.firstWhere((h) => h.id == 'financeiro');
    expect(financeiro.itens.single.abas.length, 3);
  });

  test('busca acha nome antigo via legacyIds', () {
    final groups = groupCatalogoHubs(catalogo, query: 'Receita recorrente');
    expect(groups, isNotEmpty);
    expect(
      groups.any(
        (g) => g.shortcuts.any((s) => s.entrada.matchesQuery('Receita recorrente')),
      ),
      isTrue,
    );

    final found = catalogo.findByLegacyId('lead-publico');
    expect(found, isNotNull);
    expect(found!.titulo, anyOf('Lead Público', 'Captação'));
  });

  test('atalhosHome esconde configuração inicial quando onboarding completo', () {
    final withWizard = atalhosHomeFromCatalogo(catalogo);
    expect(withWizard.any((s) => s.label.contains('Configuração')), isTrue);

    final filtered = atalhosHomeFromCatalogo(
      catalogo,
      hideOnboardingWizard: true,
    );
    expect(filtered.any((s) => s.label.contains('Configuração')), isFalse);
  });

  test('papel studio fica recolhido no groupamento', () {
    final groups = groupCatalogoHubs(catalogo);
    final studio = groups.firstWhere((g) => g.title == 'Studio');
    expect(studio.collapsed, isTrue);
    expect(groups.first.collapsed, isFalse);
  });

  test('ícones Pacotes e Loja distintos; Cobrança ≠ Receita', () {
    final vendas = catalogo.hubs.firstWhere((h) => h.id == 'vendas').itens.single;
    final pacotes = vendas.abas.firstWhere((a) => a.id == 'pacotes');
    final loja = vendas.abas.firstWhere((a) => a.id == 'loja');
    expect(ferramentasIconFor(pacotes), isNot(ferramentasIconFor(loja)));

    final fin = catalogo.hubs.firstWhere((h) => h.id == 'financeiro').itens.single;
    final cobranca = fin.abas.firstWhere((a) => a.id == 'cobranca-auto');
    final receita = fin.abas.firstWhere((a) => a.id == 'receita-recorrente');
    expect(ferramentasIconFor(cobranca), isNot(ferramentasIconFor(receita)));
  });

  test('resolveNavTarget de legacy abre item com abas', () {
    final target = catalogo.resolveNavTarget('receita-recorrente');
    expect(target, isNotNull);
    expect(target!.isHubComAbas, isTrue);
  });
}
