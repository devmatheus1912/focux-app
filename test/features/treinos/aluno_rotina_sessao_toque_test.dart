import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/aluno_rotina_screen.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTreinoRepository extends TreinoRepository {
  _FakeTreinoRepository(this.fila) : super(ApiClient());

  final RotinaFila fila;
  var buscas = 0;

  @override
  Future<RotinaFila> buscarRotina(int alunoId) async {
    buscas++;
    return fila;
  }
}

const _fila = RotinaFila(
  itens: [
    RotinaItem(
      id: 1,
      tipo: RotinaItemTipo.treino,
      treinoId: 7,
      nome: 'Peito',
      diaSemana: 1,
    ),
    RotinaItem(
      id: 2,
      tipo: RotinaItemTipo.treino,
      nome: 'Costas',
      diaSemana: 2,
    ),
  ],
);

Future<(_FakeTreinoRepository, GoRouter)> _abrir(
  WidgetTester tester,
  List<Object?> aberturas,
) async {
  final repo = _FakeTreinoRepository(_fila);
  final router = GoRouter(
    initialLocation: '/alunos/3/rotina',
    routes: [
      GoRoute(
        path: '/alunos/:id/rotina',
        builder: (context, state) =>
            const AlunoRotinaScreen(alunoId: 3, alunoNome: ' Ana '),
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) {
          aberturas.add((state.pathParameters['id'], state.extra));
          return Scaffold(
            appBar: AppBar(),
            body: const Text('montador'),
          );
        },
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [treinoRepositoryProvider.overrideWithValue(repo)],
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
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  return (repo, router);
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tocar numa sessão abre o montador com o aluno', (tester) async {
    final aberturas = <Object?>[];
    await _abrir(tester, aberturas);

    await tester.tap(find.text('Peito'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('montador'), findsOneWidget);
    expect(aberturas, hasLength(1));
    final (id, extra) = aberturas.single! as (String?, Object?);
    expect(id, '7');
    final lido = TreinoRouteExtra.parse(extra);
    expect(lido.alunoId, 3);
    expect(lido.alunoNome, 'Ana');
  });

  testWidgets('sessão sem treinoId não navega', (tester) async {
    final aberturas = <Object?>[];
    await _abrir(tester, aberturas);

    await tester.tap(find.text('Costas'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('montador'), findsNothing);
    expect(aberturas, isEmpty);
    expect(find.text('Toque para montar'), findsOneWidget);
  });

  testWidgets('voltar do montador recarrega a semana', (tester) async {
    final (repo, router) = await _abrir(tester, <Object?>[]);
    final antes = repo.buscas;

    await tester.tap(find.text('Peito'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    router.pop();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }

    expect(find.text('Peito'), findsOneWidget);
    expect(repo.buscas, greaterThan(antes));
  });
}
