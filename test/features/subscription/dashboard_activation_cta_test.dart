import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/subscription/utils/dashboard_activation_step.dart';
import 'package:focux_app/features/subscription/widgets/dashboard_activation_cta.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _destino(String nome) => Scaffold(body: Text('Destino $nome'));

Future<void> _pumpCta(
  WidgetTester tester, {
  int alunosAtivos = 3,
  bool temTreinos = true,
  bool temFinanceiro = false,
}) async {
  final router = GoRouter(
    initialLocation: '/dashboard/personal',
    routes: [
      GoRoute(
        path: '/dashboard/personal',
        builder: (context, state) => Scaffold(
          body: DashboardActivationCta(
            alunosAtivos: alunosAtivos,
            temTreinos: temTreinos,
            temFinanceiro: temFinanceiro,
          ),
        ),
      ),
      GoRoute(
        path: '/treinos/novo',
        builder: (context, state) => _destino('novo treino'),
      ),
      GoRoute(
        path: '/financeiro',
        builder: (context, state) => _destino('financeiro'),
      ),
      GoRoute(
        path: '/perfil/wallet',
        builder: (context, state) => _destino('carteira'),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      locale: const Locale('pt'),
      supportedLocales: S.supportedLocales,
      localizationsDelegates: S.localizationsDelegates,
      routerConfig: router,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('sem treino: promete modelo rápido (não IA) e abre Novo treino', (
    tester,
  ) async {
    await _pumpCta(tester, temTreinos: false);

    expect(find.text('Crie o primeiro treino'), findsOneWidget);
    expect(
      find.text('Comece por um modelo rápido e atribua ao aluno'),
      findsOneWidget,
    );
    expect(find.textContaining('IA'), findsNothing);

    await tester.tap(find.text('Crie o primeiro treino'));
    await tester.pumpAndSettle();
    expect(find.text('Destino novo treino'), findsOneWidget);
  });

  testWidgets('sem mensalidade: abre o Financeiro, não a Carteira', (
    tester,
  ) async {
    await _pumpCta(tester);

    expect(find.text('Lance a primeira mensalidade'), findsOneWidget);
    expect(
      find.text('Registre a cobrança e acompanhe o pagamento'),
      findsOneWidget,
    );
    expect(find.textContaining('automático'), findsNothing);

    await tester.tap(find.text('Lance a primeira mensalidade'));
    await tester.pumpAndSettle();
    expect(find.text('Destino financeiro'), findsOneWidget);
    expect(find.text('Destino carteira'), findsNothing);
  });

  testWidgets('ativação completa esconde a faixa', (tester) async {
    await _pumpCta(tester, temFinanceiro: true);

    expect(find.text('Lance a primeira mensalidade'), findsNothing);
    expect(find.text('Crie o primeiro treino'), findsNothing);
  });

  test('ordem: alunos → treino → financeiro', () {
    final s = lookupS(const Locale('pt'));
    DashboardActivationStep? passo({
      int alunos = 1,
      bool treinos = true,
      bool financeiro = true,
    }) => dashboardActivationStep(
      s,
      alunosAtivos: alunos,
      temTreinos: treinos,
      temFinanceiro: financeiro,
    );

    expect(passo(alunos: 0, treinos: false)?.route, '/growth/migracao');
    expect(passo(treinos: false, financeiro: false)?.route, '/treinos/novo');
    expect(passo(treinos: false)?.cta, 'Criar primeiro treino');
    expect(passo(financeiro: false)?.route, '/financeiro');
    expect(passo(financeiro: false)?.cta, 'Abrir financeiro');
    expect(passo(), isNull);
  });
}
