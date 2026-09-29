import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/app_router_redirect.dart';
import 'package:focux_app/core/router/safe_navigation.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/alunos_list_screen.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';
import 'package:focux_app/features/alunos/utils/alunos_microcopy.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final home = AlunosHomeBundle(
    alunos: [
      Aluno(
        id: 1,
        nome: 'Ana Souza',
        email: 'a***@test.com',
        status: 'ATIVO',
        objetivo: 'Força',
        aderenciaPercent: 72,
        diasSemTreino: 1,
      ),
    ],
    stats: const AlunosStats(
      total: 1,
      totalAtivos: 1,
      totalInadimplentes: 0,
      totalRiscoAlto: 0,
      totalConvites: 0,
      totalContatoHoje: 0,
    ),
    alertasConfig: AlertasConfiguracao(
      diasSemTreino: 7,
      aderenciaMinima: 50,
    ),
    page: const AlunosHomePageMeta(
      page: 0,
      size: 40,
      totalElements: 1,
      totalPages: 1,
      hasNext: false,
    ),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AlunosHomeClientCache.clear();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('lista alunos monta com Semantics e título', (tester) async {
    final router = GoRouter(
      initialLocation: '/alunos',
      routes: [
        GoRoute(
          path: '/alunos',
          builder: (context, state) => const AlunosListScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alunosHomeProvider.overrideWith((ref) async => home),
        ],
        child: MaterialApp.router(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: EagleTokens.brandAccent,
            ),
            useMaterial3: true,
          ),
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('Alunos'), findsWidgets);
    expect(find.textContaining('Contato hoje'), findsOneWidget);
    expect(find.bySemanticsLabel(AlunosMicrocopy.screenA11y), findsOneWidget);
    expect(find.byTooltip(AlunosMicrocopy.helpA11y), findsOneWidget);
  });

  group('busca vinda da Hoje (?q=)', () {
    late GoRouter router;

    Future<void> pumpAlunos(WidgetTester tester, String location) async {
      router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(
            path: '/alunos',
            builder: (context, state) => AlunosListScreen(
              initialFiltro: alunoFiltroFromQuery(
                state.uri.queryParameters['filtro'],
              ),
              initialQuery: alunoBuscaFromQuery(
                state.uri.queryParameters['q'],
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [alunosHomeProvider.overrideWith((ref) async => home)],
          child: MaterialApp.router(
            locale: const Locale('pt'),
            supportedLocales: S.supportedLocales,
            localizationsDelegates: S.localizationsDelegates,
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
    }

    AlunosHomeQuery queryAtual(WidgetTester tester) =>
        ProviderScope.containerOf(
          tester.element(find.byType(AlunosListScreen)),
        ).read(alunosHomeQueryProvider);

    String textoDaBusca(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    testWidgets('pré-preenche a busca e filtra a lista', (tester) async {
      await pumpAlunos(tester, alunosBuscaLocation(' Ana Souza '));

      expect(textoDaBusca(tester), 'Ana Souza');
      expect(queryAtual(tester).q, 'Ana Souza');
    });

    testWidgets('termo vazio mantém a lista sem busca', (tester) async {
      await pumpAlunos(tester, alunosBuscaLocation('   '));

      expect(textoDaBusca(tester), isEmpty);
      expect(queryAtual(tester).q, isEmpty);
    });

    testWidgets('nova busca com a aba já aberta troca o termo', (
      tester,
    ) async {
      await pumpAlunos(tester, '/alunos');
      expect(queryAtual(tester).q, isEmpty);

      router.go(alunosBuscaLocation('bia'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(textoDaBusca(tester), 'bia');
      expect(queryAtual(tester).q, 'bia');
    });

    testWidgets('filtro vindo da Hoje com a aba já aberta aplica', (
      tester,
    ) async {
      await pumpAlunos(tester, '/alunos');

      router.go('/alunos?filtro=risco');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(tester.takeException(), isNull);
      expect(queryAtual(tester).filtro, AlunoFiltro.risco);
    });

    testWidgets('filtro novo sem q não herda o termo antigo', (tester) async {
      await pumpAlunos(tester, alunosBuscaLocation('ana'));

      router.go('/alunos?filtro=risco');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(textoDaBusca(tester), isEmpty);
      expect(queryAtual(tester).q, isEmpty);
      expect(queryAtual(tester).filtro, AlunoFiltro.risco);
    });

    testWidgets('limpar a busca tira o q e mantém o filtro', (tester) async {
      await pumpAlunos(tester, '/alunos?filtro=risco&q=ana');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final uri = router.routerDelegate.currentConfiguration.uri;
      expect(uri.queryParameters, {'filtro': 'risco'});
      expect(textoDaBusca(tester), isEmpty);
      expect(queryAtual(tester).q, isEmpty);
      expect(queryAtual(tester).filtro, AlunoFiltro.risco);
    });
  });

  testWidgets('buscar, limpar, voltar à Hoje e buscar de novo refaz a busca', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/dashboard/personal',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => Scaffold(body: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard/personal',
                  builder: (context, state) => Scaffold(
                    body: TextButton(
                      onPressed: () => goPersonalShellTab(
                        context,
                        alunosBuscaLocation('ana'),
                      ),
                      child: const Text('Buscar ana'),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/alunos',
                  builder: (context, state) => AlunosListScreen(
                    initialQuery: alunoBuscaFromQuery(
                      state.uri.queryParameters['q'],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [alunosHomeProvider.overrideWith((ref) async => home)],
        child: MaterialApp.router(
          locale: const Locale('pt'),
          supportedLocales: S.supportedLocales,
          localizationsDelegates: S.localizationsDelegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    String textoDaBusca() =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;
    String qAtual() => ProviderScope.containerOf(
      tester.element(find.byType(AlunosListScreen)),
    ).read(alunosHomeQueryProvider).q;

    await tester.tap(find.text('Buscar ana'));
    await settle();
    expect(textoDaBusca(), 'ana');
    expect(qAtual(), 'ana');

    await tester.tap(find.byIcon(Icons.close));
    await settle();
    expect(textoDaBusca(), isEmpty);
    expect(qAtual(), isEmpty);
    expect(router.routerDelegate.currentConfiguration.uri.toString(), '/alunos');

    router.go('/dashboard/personal');
    await settle();
    await tester.tap(find.text('Buscar ana'));
    await settle();

    expect(tester.takeException(), isNull);
    expect(textoDaBusca(), 'ana');
    expect(qAtual(), 'ana');
  });

  group('busca na location', () {
    test('limpar tira só o q', () {
      expect(
        alunosLocationSemBusca(Uri.parse('/alunos?filtro=risco&q=ana')),
        '/alunos?filtro=risco',
      );
      expect(alunosLocationSemBusca(Uri.parse('/alunos?q=ana')), '/alunos');
    });

    test('termo novo compara com a busca atual, não com a rota anterior', () {
      expect(
        alunosBuscaAposNavegacao(
          busca: 'ana',
          buscaAtual: '',
          filtroMudou: false,
        ),
        'ana',
      );
      expect(
        alunosBuscaAposNavegacao(
          busca: 'ana',
          buscaAtual: ' ana ',
          filtroMudou: false,
        ),
        isNull,
      );
      expect(
        alunosBuscaAposNavegacao(
          busca: '',
          buscaAtual: 'ana',
          filtroMudou: true,
        ),
        '',
      );
      expect(
        alunosBuscaAposNavegacao(
          busca: '',
          buscaAtual: 'ana',
          filtroMudou: false,
        ),
        isNull,
      );
    });
  });

  test('query serializes filtro for BFF', () {
    expect(
      const AlunosHomeQuery(filtro: AlunoFiltro.contatoHoje).filtroApi,
      'contatoHoje',
    );
    expect(
      const AlunosHomeQuery(ordenacao: AlunoOrdenacao.nome).ordenacaoApi,
      'nome',
    );
  });
}
