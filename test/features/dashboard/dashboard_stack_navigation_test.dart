import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/router/safe_navigation.dart';
import 'package:focux_app/features/dashboard/data/command_action_item.dart';
import 'package:focux_app/features/dashboard/utils/open_dashboard_command_action.dart';
import 'package:focux_app/features/dashboard/widgets/dashboard_financial_hero_section.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shell com a Hoje numa aba e telas empilhadas fora do dock, como no app.
GoRouter _router(Widget hoje) {
  return GoRouter(
    initialLocation: '/dashboard/personal',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/personal',
                builder: (context, state) => Scaffold(body: hoje),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alunos',
                builder: (context, state) =>
                    const Scaffold(body: Text('Aba Alunos')),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/financeiro',
            builder: (context, state) =>
                const Scaffold(body: Text('Tela Financeiro')),
          ),
        ],
      ),
    ],
  );
}

Future<void> _pumpApp(WidgetTester tester, GoRouter router) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _acaoFinanceiro = CommandActionItem(
  icon: 'pix',
  title: 'Cobrar mensalidades',
  subtitle: '2 em atraso',
  route: '/financeiro',
  tone: CommandActionTone.money,
);

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('só as 5 abas do dock contam como aba', () {
    expect(isPersonalShellTabLocation('/dashboard/personal'), isTrue);
    expect(isPersonalShellTabLocation('/alunos?q=ana'), isTrue);
    expect(isPersonalShellTabLocation('/ia/copiloto'), isTrue);
    expect(isPersonalShellTabLocation('/financeiro'), isFalse);
    expect(isPersonalShellTabLocation('/assinatura'), isFalse);
    expect(isPersonalShellTabLocation('/alunos/12'), isFalse);
    expect(isPersonalShellTabLocation('/checkin'), isFalse);
  });

  testWidgets('ação da Hoje empilha a tela e Voltar retorna à Hoje', (
    tester,
  ) async {
    final router = _router(
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => openDashboardCommandAction(
            context: context,
            ref: ref,
            item: _acaoFinanceiro,
          ),
          child: const Text('Abrir ação'),
        ),
      ),
    );
    await _pumpApp(tester, router);

    await tester.tap(find.text('Abrir ação'));
    await tester.pumpAndSettle();
    expect(find.text('Tela Financeiro'), findsOneWidget);

    final handled = await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.text('Abrir ação'), findsOneWidget);
    expect(find.text('Tela Financeiro'), findsNothing);
  });

  testWidgets('ação da Hoje para aba do dock troca de aba', (tester) async {
    final router = _router(
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => openDashboardCommandAction(
            context: context,
            ref: ref,
            item: const CommandActionItem(
              icon: 'users',
              title: 'Alunos em risco',
              subtitle: '3 alunos',
              route: '/alunos',
              tone: CommandActionTone.hot,
            ),
          ),
          child: const Text('Abrir ação'),
        ),
      ),
    );
    await _pumpApp(tester, router);

    await tester.tap(find.text('Abrir ação'));
    await tester.pumpAndSettle();

    expect(find.text('Aba Alunos'), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/alunos');
  });

  testWidgets('panorama financeiro abre Financeiro empilhado', (tester) async {
    final router = _router(
      const SingleChildScrollView(
        child: DashboardFinancialHeroSection(
          mes: 'setembro',
          receitaAtual: 0,
          pendente: 0,
          progressRaw: 0,
          metaSuperada: false,
          loadingFin: false,
          finData: null,
        ),
      ),
    );
    await _pumpApp(tester, router);

    await tester.tap(find.text('Abrir financeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Tela Financeiro'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Tela Financeiro'), findsNothing);
    expect(find.text('Abrir financeiro'), findsOneWidget);
  });
}
