import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_modelo.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_modelos_provider.dart';
import 'package:focux_app/features/treinos/widgets/modelo_contexto_treino.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/features/treinos/utils/treino_blocos.dart';
import 'package:focux_app/features/treinos/widgets/ficha_contexto_treino.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

TreinoExercicioItem _item(int id, String bloco, int ordem) => TreinoExercicioItem(
  id: id,
  exercicio: Exercicio(
    id: id + 100,
    nome: 'Exercício $id',
    grupoMuscularPrimario: GrupoMuscular.peito,
  ),
  series: 3,
  repeticoes: '10',
  ordem: ordem,
  bloco: bloco,
);

const _rotina = RotinaFila(
  itens: [
    RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 9, nome: 'Treino A', diaSemana: 1, exerciciosCount: 2),
    RotinaItem(id: 2, tipo: RotinaItemTipo.treino, treinoId: 10, nome: 'Treino B', diaSemana: 3, exerciciosCount: 0),
  ],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _modelo = FichaModelo(
  id: 31,
  nome: 'Hipertrofia 4 dias',
  itens: [
    FichaModeloItem(descanso: false, treinoId: 9, nome: 'Treino A', diaSemana: 1, exerciciosCount: 2),
    FichaModeloItem(descanso: false, treinoId: 10, nome: 'Treino B', diaSemana: 2, exerciciosCount: 0),
  ],
);

Widget _app(GoRouter router, {RotinaFila rotina = _rotina, Treino? treino}) =>
    ProviderScope(
      overrides: [
        alunoRotinaProvider(3).overrideWith((ref) async => rotina),
        fichaModeloProvider(31).overrideWith((ref) async => _modelo),
        if (treino != null) treinoProvider.overrideWith((ref, id) async => treino),
      ],
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
    );

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('blocos do treino', () {
    final todos = [
      _item(1, 'AQUECIMENTO', 0),
      _item(2, 'TRABALHO', 1),
      _item(3, 'TRABALHO', 2),
      _item(4, 'ALONGAMENTO', 3),
    ];

    test('só os blocos com exercício, na ordem da tela', () {
      final blocos = blocosComExercicio([...todos]..shuffle());
      expect(blocos.map((b) => b.$1), ['AQUECIMENTO', 'TRABALHO', 'ALONGAMENTO']);
      expect(blocos[1].$2.map((e) => e.id), containsAll([2, 3]));
    });

    test('Ajuste continua aparecendo se já houver exercício nele', () {
      final blocos = blocosComExercicio([_item(5, 'AJUSTE', 0), _item(6, 'TRABALHO', 1)]);
      expect(blocos.map((b) => b.$1), ['TRABALHO', 'AJUSTE']);
    });

    test('título de bloco só quando ajuda', () {
      expect(mostrarTituloDeBloco(blocosComExercicio([_item(1, 'TRABALHO', 0)])), isFalse);
      expect(mostrarTituloDeBloco(blocosComExercicio([_item(1, 'AQUECIMENTO', 0)])), isTrue);
      expect(mostrarTituloDeBloco(blocosComExercicio(todos)), isTrue);
      expect(mostrarTituloDeBloco(const []), isFalse);
    });

    test('reordenar um bloco manda todos os ids do treino', () {
      final ids = idsCompletosAoReordenar(
        todos: todos,
        doBloco: [todos[1], todos[2]],
        novaOrdemDoBloco: [3, 2],
      );
      expect(ids, [1, 3, 2, 4]);
    });
  });

  group('contexto da ficha', () {
    Future<GoRouter> abrir(WidgetTester tester, {RotinaFila rotina = _rotina, int treinoId = 9}) async {
      final router = GoRouter(
        initialLocation: '/inicio',
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => Scaffold(
              body: FichaContextoDoTreino(alunoId: 3, alunoNome: ' Ana ', treinoId: treinoId),
            ),
          ),
          GoRoute(
            path: '/treinos/:id',
            builder: (context, state) =>
                Text('treino ${state.pathParameters['id']} ${state.extra}'),
          ),
        ],
      );
      await tester.pumpWidget(_app(router, rotina: rotina));
      await _settle(tester);
      return router;
    }

    testWidgets('diz de quem é a sessão e de que dia', (tester) async {
      await abrir(tester);
      expect(find.text('Ficha de Ana · Seg'), findsOneWidget);
    });

    testWidgets('a fileira troca de sessão sem voltar, mantendo o aluno', (tester) async {
      await abrir(tester);
      expect(find.text('Treino A'), findsOneWidget);
      expect(find.text('Treino B'), findsOneWidget);

      await tester.tap(find.text('Treino B'));
      await _settle(tester);

      expect(find.textContaining('treino 10'), findsOneWidget);
      expect(find.textContaining('alunoId: 3'), findsOneWidget);
    });

    testWidgets('uma única sessão não mostra fileira', (tester) async {
      await abrir(
        tester,
        rotina: const RotinaFila(
          itens: [
            RotinaItem(id: 1, tipo: RotinaItemTipo.treino, treinoId: 9, nome: 'Treino A', diaSemana: 1),
          ],
        ),
      );
      expect(find.text('Ficha de Ana · Seg'), findsOneWidget);
      expect(find.text('Treino A'), findsNothing);
    });

    testWidgets('treino que não está na ficha não mostra contexto', (tester) async {
      await abrir(tester, treinoId: 77);
      expect(find.textContaining('Ficha de'), findsNothing);
    });
  });

  group('tela de dentro do treino', () {
    final treino = Treino(
      id: 9,
      nome: 'Treino A',
      exercicios: [
        _item(1, 'AQUECIMENTO', 0),
        _item(2, 'TRABALHO', 1),
      ],
    );

    Future<void> abrir(WidgetTester tester, {int? alunoId}) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/treinos/9',
        routes: [
          GoRoute(
            path: '/treinos/:id',
            builder: (context, state) => TreinoDetailScreen(
              treinoId: 9,
              alunoId: alunoId,
              alunoNome: alunoId == null ? null : 'Ana',
            ),
          ),
        ],
      );
      await tester.pumpWidget(_app(router, treino: treino));
      await _settle(tester);
    }

    testWidgets('aberta pela ficha: mostra o contexto e esconde Atribuir', (tester) async {
      await abrir(tester, alunoId: 3);
      expect(find.text('Ficha de Ana · Seg'), findsOneWidget);
      expect(find.text('Atribuir'), findsNothing);
    });

    testWidgets('aberta pelos modelos: continua com Atribuir', (tester) async {
      await abrir(tester);
      expect(find.text('Atribuir'), findsOneWidget);
      expect(find.textContaining('Ficha de'), findsNothing);
    });

    testWidgets('blocos viram seções, sem a faixa de "Pular"', (tester) async {
      await abrir(tester, alunoId: 3);
      expect(find.textContaining('Pular'), findsNothing);
      expect(find.text('Aquecimento'), findsOneWidget);
      expect(find.text('Trabalho'), findsOneWidget);
      expect(find.text('Exercício 1'), findsOneWidget);
      expect(find.text('Exercício 2'), findsOneWidget);
      expect(find.text('Alongamento'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });
  });

  group('contexto do modelo', () {
    Future<void> abrirContexto(WidgetTester tester, {int treinoId = 9}) async {
      final router = GoRouter(
        initialLocation: '/inicio',
        routes: [
          GoRoute(
            path: '/inicio',
            builder: (context, state) => Scaffold(
              body: ModeloContextoDoTreino(modeloId: 31, treinoId: treinoId),
            ),
          ),
          GoRoute(
            path: '/treinos/:id',
            builder: (context, state) => Text('treino ${state.pathParameters['id']} ${state.extra}'),
          ),
        ],
      );
      await tester.pumpWidget(_app(router));
      await _settle(tester);
    }

    testWidgets('diz de qual modelo é a sessão', (tester) async {
      await abrirContexto(tester);
      expect(find.text('Modelo: Hipertrofia 4 dias'), findsOneWidget);
      expect(find.text('Treino A'), findsOneWidget);
      expect(find.text('Treino B'), findsOneWidget);
    });

    testWidgets('trocar de sessão mantém o modelo e não leva aluno', (tester) async {
      await abrirContexto(tester);
      await tester.tap(find.text('Treino B'));
      await _settle(tester);

      expect(find.textContaining('treino 10'), findsOneWidget);
      expect(find.textContaining('modeloId: 31'), findsOneWidget);
      expect(find.textContaining('alunoId'), findsNothing);
    });

    testWidgets('a tela aberta por um modelo mostra o contexto e esconde Atribuir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/treinos/9',
        routes: [
          GoRoute(
            path: '/treinos/:id',
            builder: (context, state) => const TreinoDetailScreen(treinoId: 9, modeloId: 31),
          ),
        ],
      );
      await tester.pumpWidget(
        _app(router, treino: Treino(id: 9, nome: 'Treino A', exercicios: [_item(1, 'TRABALHO', 0)])),
      );
      await _settle(tester);

      expect(find.text('Modelo: Hipertrofia 4 dias'), findsOneWidget);
      expect(find.text('Atribuir'), findsNothing);
      expect(find.textContaining('Ficha de'), findsNothing);
    });
  });
}
