import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_toggle_chip.dart';
import 'package:focux_app/features/alertas/data/alertas_repository.dart';
import 'package:focux_app/features/alunos/data/aluno_repository.dart';
import 'package:focux_app/features/alunos/providers/alunos_provider.dart';
import 'package:focux_app/features/alunos/screens/alunos_list_screen.dart';
import 'package:focux_app/features/alunos/utils/alunos_home_client_cache.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

AlunosHomeBundle _home(List<Aluno> alunos, AlunosStats stats) => AlunosHomeBundle(
  alunos: alunos,
  stats: stats,
  alertasConfig: AlertasConfiguracao(diasSemTreino: 7, aderenciaMinima: 50),
  page: AlunosHomePageMeta(
    page: 0,
    size: 40,
    totalElements: alunos.length,
    totalPages: 1,
    hasNext: false,
  ),
);

final _alunos = [
  Aluno(
    id: 1,
    nome: 'Ana Souza',
    email: 'a***@test.com',
    status: 'ATIVO',
    objetivo: 'Força',
    contaAtiva: true,
    diasSemTreino: 1,
  ),
  Aluno(
    id: 2,
    nome: 'guilherme -',
    email: 'g***@test.com',
    status: 'ATIVO',
    contaAtiva: false,
  ),
  Aluno(
    id: 3,
    nome: 'Hugo Lima',
    email: 'h***@test.com',
    status: 'ATIVO',
    emRisco: true,
    contaAtiva: true,
    diasSemTreino: 9,
  ),
];

const _stats = AlunosStats(
  total: 3,
  totalAtivos: 3,
  totalInadimplentes: 0,
  totalRiscoAlto: 1,
  totalConvites: 1,
  totalContatoHoje: 1,
);

Future<void> _abrir(WidgetTester tester, AlunosHomeBundle home) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/alunos',
    routes: [
      GoRoute(path: '/alunos', builder: (_, __) => const AlunosListScreen()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [alunosHomeProvider.overrideWith((ref) async => home)],
      child: MaterialApp.router(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: EagleTokens.brandAccent),
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
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Set<String> _marcados(WidgetTester tester) => tester
    .widgetList<FxToggleChip>(find.byType(FxToggleChip))
    .where((c) => c.selected)
    .map((c) => c.label)
    .toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AlunosPendingSearch.consume();
    SharedPreferences.setMockInitialValues({});
    AlunosHomeClientCache.clear();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('filtros', () {
    testWidgets('Todos marcado sem filtro; chips só com o que mostrar', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(_marcados(tester), {'Todos'});
      expect(find.text('Contato hoje 1'), findsOneWidget);
      expect(find.text('Ativos 3'), findsOneWidget);
      expect(find.text('Em risco 1'), findsOneWidget);
      expect(find.text('Convites 1'), findsOneWidget);
      expect(find.textContaining('Em atraso'), findsNothing);
    });

    testWidgets('chip com zero não aparece', (tester) async {
      await _abrir(
        tester,
        _home(
          [_alunos.first],
          const AlunosStats(
            total: 1,
            totalAtivos: 1,
            totalInadimplentes: 0,
            totalRiscoAlto: 0,
            totalConvites: 0,
            totalContatoHoje: 0,
          ),
        ),
      );

      expect(find.textContaining('Contato hoje'), findsNothing);
      expect(find.textContaining('Em risco'), findsNothing);
      expect(find.textContaining('Convites'), findsNothing);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Ativos 1'), findsOneWidget);
    });

    testWidgets('tocar no chip marcado não desliga; o Todos volta', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      await tester.ensureVisible(find.text('Em risco 1'));
      await tester.tap(find.text('Em risco 1'));
      await _assentar(tester);
      expect(_marcados(tester), {'Em risco 1'});

      await tester.ensureVisible(find.text('Em risco 1'));
      await tester.tap(find.text('Em risco 1'));
      await _assentar(tester);
      expect(_marcados(tester), {'Em risco 1'});

      await tester.ensureVisible(find.text('Todos'));
      await tester.tap(find.text('Todos'));
      await _assentar(tester);
      expect(_marcados(tester), {'Todos'});
    });
  });

  group('sem banner', () {
    testWidgets('o aviso de contato não aparece como banner', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.textContaining('precisam de contato hoje'), findsNothing);
      expect(find.text('Focar agora'), findsNothing);
    });
  });

  group('card', () {
    testWidgets('convidado: "Ainda não entrou" e botão Reenviar de 48 dp', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.text('Ainda não entrou'), findsOneWidget);
      final reenviar = find.widgetWithText(OutlinedButton, 'Reenviar');
      expect(reenviar, findsOneWidget);
      expect(tester.getSize(reenviar).height, greaterThanOrEqualTo(48));
      expect(find.text('Reenviar convite'), findsNothing);
    });

    testWidgets('nunca mostra "Objetivo pendente"; sem objetivo, o e-mail', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.textContaining('Objetivo pendente'), findsNothing);
      expect(find.text('Força'), findsOneWidget);
    });

    testWidgets('parado há 9 dias aparece uma vez só', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.text('Parado há 9 dias'), findsOneWidget);
      expect(find.textContaining('Parado há 9d'), findsNothing);
    });

    testWidgets('nome sem sobra de import', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.text('Guilherme'), findsOneWidget);
      expect(find.textContaining('Guilherme -'), findsNothing);
    });
  });

  group('rodapé', () {
    testWidgets('um botão principal e o de importar só com ícone', (tester) async {
      await _abrir(tester, _home(_alunos, _stats));

      expect(find.text('Novo aluno'), findsOneWidget);
      expect(find.byTooltip('Importar vários'), findsOneWidget);
      expect(find.text('Importar vários'), findsNothing);
    });

    testWidgets('sem nenhum aluno, os dois viram botões com texto', (tester) async {
      await _abrir(
        tester,
        _home(
          const [],
          const AlunosStats(
            total: 0,
            totalAtivos: 0,
            totalInadimplentes: 0,
            totalRiscoAlto: 0,
            totalConvites: 0,
            totalContatoHoje: 0,
          ),
        ),
      );

      expect(find.text('Novo aluno'), findsWidgets);
      expect(find.widgetWithText(OutlinedButton, 'Importar vários'), findsOneWidget);
    });
  });
}
