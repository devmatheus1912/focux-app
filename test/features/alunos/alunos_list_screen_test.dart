import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/constants/alunos_list_filters.dart';
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
    expect(find.bySemanticsLabel(AlunosMicrocopy.screenA11y), findsOneWidget);
    expect(find.byTooltip(AlunosMicrocopy.helpA11y), findsOneWidget);
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
