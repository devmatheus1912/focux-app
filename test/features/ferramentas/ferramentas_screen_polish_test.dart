import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/dashboard/data/dashboard_tool_shortcuts.dart';
import 'package:focux_app/features/dashboard/utils/dashboard_tool_groups.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_bootstrap.dart';
import 'package:focux_app/features/ferramentas/data/ferramentas_catalogo_models.dart';
import 'package:focux_app/features/ferramentas/providers/ferramentas_catalogo_provider.dart';
import 'package:focux_app/features/ferramentas/screens/ferramentas_screen.dart';
import 'package:focux_app/features/ferramentas/utils/ferramentas_agrupar.dart';
import 'package:focux_app/features/planos/data/planos_repository.dart';
import 'package:focux_app/features/subscription/models/subscription_plan.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/riverpod_seeds.dart';

class _Catalogo extends FerramentasCatalogoNotifier {
  _Catalogo(this.catalogo);

  final FerramentasCatalogo catalogo;

  @override
  Future<FerramentasCatalogo> build() async => catalogo;
}

FerramentasCatalogo _catalogo() => FerramentasCatalogo.fromJson({
  'version': 1,
  'hubs': [
    {
      'id': 'operacao',
      'titulo': 'Operação',
      'itens': [
        {'id': 'exercicios', 'titulo': 'Exercícios', 'subtitulo': 'Sua biblioteca de movimentos', 'rotaApp': '/exercicios', 'unlocked': true},
        {'id': 'desafios', 'titulo': 'Desafios', 'rotaApp': '/desafios', 'unlocked': true},
      ],
    },
    {
      'id': 'captacao',
      'titulo': 'Captação',
      'itens': [
        {'id': 'captacao', 'titulo': 'Captação', 'subtitulo': 'Leads públicos e landing', 'rotaApp': '/leads-publicos', 'unlocked': true},
      ],
    },
    {
      'id': 'vendas',
      'titulo': 'Vendas',
      'itens': [
        {'id': 'vendas', 'titulo': 'Vendas', 'rotaApp': '/pacotes', 'unlocked': true},
      ],
    },
  ],
});

Future<void> _abrir(WidgetTester tester, FerramentasCatalogo catalogo) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.binding.setSurfaceSize(const Size(430, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  const features = PlanoFeatures(
    plano: SubscriptionPlan.PRO,
    financeiro: true,
    agenda: true,
    relatorios: true,
    whiteLabel: false,
    iaCopiloto: true,
    migracaoFoto: false,
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        seededPlanoFeatures(features),
        ferramentasCatalogoProvider.overrideWith(() => _Catalogo(catalogo)),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
          useMaterial3: true,
        ),
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        home: const FerramentasScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Ferramentas cumpre o contrato das telas', () {
    final fonte = File('lib/features/ferramentas/screens/ferramentas_screen.dart').readAsStringSync();
    expect(fonte, contains('fxScreenA11yScope'));
    expect(fonte, contains('SkeletonList'));
    expect(fonte, isNot(contains('CircularProgressIndicator')));
    expect(fonte, contains('FxShellScaffold'));
    expect(fonte, isNot(contains("'Buscar ferramenta ou nome antigo")));
  });

  group('agruparFerramentas', () {
    List<DashboardToolGroupSection> grupos() => groupCatalogoHubs(_catalogo());

    test('grupo de um item com o mesmo nome perde o cabeçalho e junta com o vizinho', () {
      final saida = agruparFerramentas(grupos());
      expect(saida.map((g) => g.title), ['Operação', '']);
      expect(saida.last.shortcuts.map((a) => a.label), ['Captação', 'Vendas']);
    });

    test('grupo de verdade fica como está', () {
      final saida = agruparFerramentas(grupos());
      expect(saida.first.shortcuts, hasLength(2));
    });

    test('um grupo de um item com nome diferente mantém o cabeçalho', () {
      final catalogo = FerramentasCatalogo.fromJson({
        'version': 1,
        'hubs': [
          {
            'id': 'financeiro',
            'titulo': 'Financeiro',
            'itens': [
              {'id': 'recorrencia', 'titulo': 'Recorrência', 'rotaApp': '/recorrencia', 'unlocked': true},
            ],
          },
        ],
      });
      final saida = agruparFerramentas(groupCatalogoHubs(catalogo));
      expect(saida.single.title, 'Financeiro');
    });

    test('lista vazia continua vazia', () {
      expect(agruparFerramentas(const []), isEmpty);
    });
  });

  test('a descrição do servidor aparece; vazia ou igual ao nome não', () {
    DashboardToolShortcut atalho(String titulo, String? subtitulo) => DashboardToolShortcut.fromEntrada(
      CatalogoEntrada(id: 'x', titulo: titulo, subtitulo: subtitulo, rotaApp: '/x'),
    );
    expect(atalho('Captação', 'Leads públicos e landing').descricao, 'Leads públicos e landing');
    expect(atalho('Captação', '  ').descricao, isNull);
    expect(atalho('Captação', 'captação').descricao, isNull);
    expect(atalho('Captação', null).descricao, isNull);
  });

  testWidgets('lista os itens com descrição e sem cabeçalho repetido', (tester) async {
    await _abrir(tester, _catalogo());

    expect(find.text('Ferramentas'), findsWidgets);
    expect(find.text('Exercícios'), findsOneWidget);
    expect(find.text('Sua biblioteca de movimentos'), findsOneWidget);
    expect(find.text('Leads públicos e landing'), findsOneWidget);
    // "Captação" e "Vendas" aparecem uma vez só (como item), sem título de grupo.
    expect(find.text('Captação'), findsOneWidget);
    expect(find.text('Vendas'), findsOneWidget);
    expect(find.textContaining('nome antigo'), findsNothing);
  });

  testWidgets('a busca filtra e o vazio avisa', (tester) async {
    await _abrir(tester, _catalogo());

    await tester.enterText(find.byType(TextField), 'exerc');
    await tester.pump();
    expect(find.text('Exercícios'), findsOneWidget);
    expect(find.text('Vendas'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('Nenhuma ferramenta encontrada'), findsOneWidget);
  });

  testWidgets('catálogo local do app também abre sem erro', (tester) async {
    await _abrir(tester, ferramentasCatalogoBootstrap());
    expect(tester.takeException(), isNull);
    expect(find.byType(FerramentasScreen), findsOneWidget);
  });
}
