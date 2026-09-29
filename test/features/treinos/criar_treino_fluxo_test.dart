import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/api/offline_queued_ack.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/features/exercicios/data/enums.dart';
import 'package:focux_app/features/exercicios/data/exercicio_page.dart';
import 'package:focux_app/features/exercicios/data/exercicio_repository.dart';
import 'package:focux_app/features/exercicios/providers/exercicio_picker_provider.dart';
import 'package:focux_app/features/treinos/data/treino_repository.dart';
import 'package:focux_app/features/treinos/providers/treinos_provider.dart';
import 'package:focux_app/features/treinos/screens/add_exercicio_to_treino_screen.dart';
import 'package:focux_app/features/treinos/screens/create_treino_screen.dart';
import 'package:focux_app/features/treinos/screens/treino_detail_screen.dart';
import 'package:focux_app/features/treinos/utils/create_treino_logic.dart';
import 'package:focux_app/features/treinos/utils/treino_criacao_fluxo.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeTreinoRepository extends TreinoRepository {
  _FakeTreinoRepository({this.offline = false, this.falhasAtribuir = 0})
    : super(ApiClient());

  final bool offline;
  int falhasAtribuir;
  final atribuicoes = <(int, int)>[];
  final tentativasAtribuir = <int>[];
  final nonces = <String>[];
  var _proximoId = 12;

  @override
  Future<Treino> criar(
    String nome,
    String? descricao,
    String? objetivo,
    String? nivel, {
    required String formNonce,
    bool offlineQueue = true,
  }) async {
    nonces.add(formNonce);
    if (offline) throw const OfflineQueuedException();
    return Treino(id: _proximoId++, nome: nome, exercicios: const []);
  }

  @override
  Future<void> atribuirAluno(
    int treinoId,
    int alunoId, {
    DateTime? dataFim,
  }) async {
    tentativasAtribuir.add(treinoId);
    if (falhasAtribuir > 0) {
      falhasAtribuir--;
      throw Exception('falha');
    }
    atribuicoes.add((treinoId, alunoId));
  }
}

final _treinoMontado = Treino(
  id: 12,
  nome: 'Treino Hipertrofia',
  exercicios: [
    TreinoExercicioItem(
      id: 1,
      exercicio: Exercicio(
        id: 11,
        nome: 'Supino reto',
        grupoMuscularPrimario: GrupoMuscular.peito,
      ),
      series: 3,
      repeticoes: '10-12',
      descansoSegundos: 60,
      ordem: 0,
    ),
  ],
);

GoRouter _router({required String origem, Object? extraNovo}) {
  return GoRouter(
    initialLocation: origem,
    routes: [
      GoRoute(
        path: '/treinos',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/treinos/novo', extra: extraNovo),
            child: const Text('Lista de treinos'),
          ),
        ),
      ),
      GoRoute(
        path: '/alunos/5',
        builder: (context, state) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/treinos/novo', extra: extraNovo),
            child: const Text('Aluno 360'),
          ),
        ),
      ),
      GoRoute(
        path: '/treinos/novo',
        builder: (context, state) {
          final extra = TreinoRouteExtra.parse(state.extra);
          return CreateTreinoScreen(
            alunoId: extra.alunoId,
            alunoNome: extra.alunoNome,
          );
        },
      ),
      GoRoute(
        path: '/treinos/:id/exercicios/add',
        builder: (context, state) {
          final extra = TreinoRouteExtra.parse(state.extra);
          return AddExercicioToTreinoScreen(
            treinoId: int.parse(state.pathParameters['id']!),
            alunoId: extra.alunoId,
            recemCriado: extra.recemCriado,
          );
        },
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) {
          final extra = TreinoRouteExtra.parse(state.extra);
          return TreinoDetailScreen(
            treinoId: int.parse(state.pathParameters['id']!),
            alunoId: extra.alunoId,
            alunoNome: extra.alunoNome,
            recemCriado: extra.recemCriado,
          );
        },
      ),
    ],
  );
}

Future<void> _pumpFluxo(
  WidgetTester tester,
  GoRouter router,
  _FakeTreinoRepository repo, {
  List<Override> extra = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...extra,
        treinoRepositoryProvider.overrideWithValue(repo),
        treinoProvider.overrideWith((ref, id) async => _treinoMontado),
        treinoPickerHomeProvider(12).overrideWith(
          (ref) async => TreinoPickerHomeBundle(
            treino: _treinoMontado,
            libraryCount: 2,
            shortcuts: const [],
            uiHints: TreinoPickerUiHints.fallback(librarySize: 2),
          ),
        ),
        exercicioPickerPageProvider.overrideWith(
          (ref, query) async => ExercicioPickerPage(
            content: [Exercicio(id: 1, nome: 'Supino reto')],
            meta: const ExercicioPageMeta(
              page: 0,
              size: 30,
              totalElements: 1,
              totalPages: 1,
              hasNext: false,
            ),
          ),
        ),
        exercicioPickerStatsProvider.overrideWith(
          (ref) async =>
              const ExercicioPickerStats(total: 1, porGrupo: {'PEITO': 1}),
        ),
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
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _criarTreino(WidgetTester tester, String origemLabel) async {
  await tester.tap(find.text(origemLabel));
  await _settle(tester);
  await tester.enterText(find.byType(TextFormField).first, 'Treino A');
  await tester.pump();
  await tester.tap(find.text('Criar'));
  await _settle(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('regras do fluxo', () {
    test('extra ida e volta preserva aluno e recém-criado', () {
      final extra =
          const TreinoRouteExtra(
            alunoId: 5,
            alunoNome: 'Aluno',
            recemCriado: true,
          ).toExtra();
      final lido = TreinoRouteExtra.parse(extra);
      expect(lido.alunoId, 5);
      expect(lido.alunoNome, 'Aluno');
      expect(lido.recemCriado, isTrue);
      expect(const TreinoRouteExtra().toExtra(), isNull);
      expect(TreinoRouteExtra.parse({'alunoId': '7'}).alunoId, 7);
      expect(TreinoRouteExtra.parse(null).recemCriado, isFalse);
    });

    test('Concluir só abre o detalhe no treino novo sem aluno', () {
      expect(
        addExercicioConcluirDestino(treinoId: 12, recemCriado: true),
        '/treinos/12',
      );
      expect(
        addExercicioConcluirDestino(
          treinoId: 12,
          recemCriado: true,
          alunoId: 5,
        ),
        isNull,
      );
      expect(
        addExercicioConcluirDestino(treinoId: 12, recemCriado: false),
        isNull,
      );
    });

    test('Atribuir é primária só no recém-criado, montado e sem aluno', () {
      bool destaque({
        bool recemCriado = true,
        int? alunoId,
        bool atribuido = false,
        bool temExercicios = true,
      }) => treinoDetailAtribuirEmDestaque(
        recemCriado: recemCriado,
        alunoId: alunoId,
        atribuido: atribuido,
        temExercicios: temExercicios,
      );

      expect(destaque(), isTrue);
      expect(destaque(recemCriado: false), isFalse);
      expect(destaque(alunoId: 5), isFalse);
      expect(destaque(atribuido: true), isFalse);
      expect(destaque(temExercicios: false), isFalse);
    });

    test('sair com treino criado avisa que falta atribuir, sem descartar', () {
      CreateTreinoSaida saida({bool preenchido = false, bool criado = false}) =>
          CreateTreinoLogic.saida(preenchido: preenchido, treinoCriado: criado);

      expect(saida(), CreateTreinoSaida.livre);
      expect(saida(preenchido: true), CreateTreinoSaida.descartar);
      expect(saida(criado: true), CreateTreinoSaida.treinoSemAluno);
      expect(
        saida(preenchido: true, criado: true),
        CreateTreinoSaida.treinoSemAluno,
      );
    });
  });

  testWidgets(
    'criar treino → Concluir abre o detalhe com Atribuir e Voltar cai na lista',
    (tester) async {
      final repo = _FakeTreinoRepository();
      final router = _router(origem: '/treinos');
      await _pumpFluxo(tester, router, repo);

      await _criarTreino(tester, 'Lista de treinos');
      expect(find.text('Concluir'), findsOneWidget);

      await tester.tap(find.text('Concluir'));
      await _settle(tester);

      expect(find.bySemanticsLabel('Detalhe do treino'), findsOneWidget);
      expect(
        find.widgetWithText(FxLiquidPrimaryButton, 'Atribuir a aluno'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, 'Adicionar exercício'),
        findsOneWidget,
      );

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.text('Lista de treinos'), findsOneWidget);
      expect(find.text('Concluir'), findsNothing);
      expect(find.text('Criar'), findsNothing);
    },
  );

  testWidgets('vindo do Aluno 360, Concluir volta para o aluno', (
    tester,
  ) async {
    final repo = _FakeTreinoRepository();
    final router = _router(
      origem: '/alunos/5',
      extraNovo: const {'alunoId': 5, 'alunoNome': 'Aluno'},
    );
    await _pumpFluxo(tester, router, repo);

    await _criarTreino(tester, 'Aluno 360');
    expect(repo.atribuicoes, [(12, 5)]);

    await tester.tap(find.text('Concluir'));
    await _settle(tester);

    expect(find.text('Aluno 360'), findsOneWidget);
    expect(find.bySemanticsLabel('Detalhe do treino'), findsNothing);
  });

  testWidgets('falha ao atribuir: reenvio só atribui, sem 2º treino', (
    tester,
  ) async {
    final repo = _FakeTreinoRepository(falhasAtribuir: 1);
    final router = _router(
      origem: '/alunos/5',
      extraNovo: const {'alunoId': 5, 'alunoNome': 'Aluno'},
    );
    var cargasDaLista = 0;
    await _pumpFluxo(
      tester,
      router,
      repo,
      extra: [
        treinosHomeProvider.overrideWith((ref) {
          cargasDaLista++;
          return Completer<TreinosHomeBundle>().future;
        }),
      ],
    );
    final lista = ProviderScope.containerOf(
      tester.element(find.text('Aluno 360')),
    ).listen(treinosHomeProvider, (_, _) {});
    addTearDown(lista.close);
    expect(cargasDaLista, 1);

    await _criarTreino(tester, 'Aluno 360');
    expect(find.text('Treino criado, falta atribuir ao aluno'), findsOneWidget);
    expect(find.textContaining('O treino já foi criado'), findsOneWidget);
    expect(
      find.textContaining('Não foi possível atribuir ao aluno.'),
      findsOneWidget,
    );
    expect(find.textContaining('Erro ao criar treino'), findsNothing);
    expect(find.text('Criar'), findsNothing);
    expect(cargasDaLista, 2, reason: 'lista recarrega logo após criar');

    await tester.enterText(find.byType(TextFormField).first, 'Outro nome');
    await tester.pump();
    await tester.tap(find.text('Tentar atribuir de novo'));
    await _settle(tester);

    expect(repo.nonces, hasLength(1));
    expect(repo.tentativasAtribuir, [12, 12]);
    expect(repo.atribuicoes, [(12, 5)]);
    expect(find.text('Concluir'), findsOneWidget);
  });

  for (final viaVoltar in [false, true]) {
    testWidgets(
      'falha ao atribuir: sair avisa que o treino existe '
      '(${viaVoltar ? 'voltar' : 'Cancelar'})',
      (tester) async {
        final repo = _FakeTreinoRepository(falhasAtribuir: 1);
        final router = _router(
          origem: '/alunos/5',
          extraNovo: const {'alunoId': 5, 'alunoNome': 'Aluno'},
        );
        await _pumpFluxo(tester, router, repo);

        await _criarTreino(tester, 'Aluno 360');
        if (viaVoltar) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.text('Cancelar'));
        }
        await _settle(tester);

        expect(find.text('Sair sem atribuir?'), findsOneWidget);
        expect(
          find.text(
            'O treino já foi criado, mas ainda não foi atribuído ao aluno. '
            'Você pode atribuir depois pela lista de treinos.',
          ),
          findsOneWidget,
        );
        expect(find.text('Descartar treino?'), findsNothing);
        expect(find.text('O que você preencheu não será salvo.'), findsNothing);

        await tester.tap(find.text('Sair e atribuir depois'));
        await _settle(tester);

        expect(find.text('Aluno 360'), findsOneWidget);
        expect(find.text('Sair sem atribuir?'), findsNothing);
        expect(repo.nonces, hasLength(1));
        expect(repo.atribuicoes, isEmpty);
      },
    );
  }

  testWidgets('sair sem criar continua pedindo para descartar', (
    tester,
  ) async {
    final router = _router(origem: '/treinos');
    await _pumpFluxo(tester, router, _FakeTreinoRepository());

    await tester.tap(find.text('Lista de treinos'));
    await _settle(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Treino A');
    await tester.pump();
    await tester.tap(find.text('Cancelar'));
    await _settle(tester);

    expect(find.text('Descartar treino?'), findsOneWidget);
    expect(find.text('Sair sem atribuir?'), findsNothing);
  });

  testWidgets('criado offline (enfileirado) não abre detalhe sem id', (
    tester,
  ) async {
    final repo = _FakeTreinoRepository(offline: true);
    final router = _router(origem: '/treinos');
    await _pumpFluxo(tester, router, repo);

    await _criarTreino(tester, 'Lista de treinos');

    expect(find.text('Lista de treinos'), findsOneWidget);
    expect(find.text('Concluir'), findsNothing);
    expect(find.bySemanticsLabel('Detalhe do treino'), findsNothing);
  });

  testWidgets('menu do detalhe explica atribuir × copiar', (tester) async {
    final router = GoRouter(
      initialLocation: '/treinos/12',
      routes: [
        GoRoute(
          path: '/treinos/:id',
          builder: (context, state) => const TreinoDetailScreen(treinoId: 12),
        ),
      ],
    );
    await _pumpFluxo(tester, router, _FakeTreinoRepository());

    expect(
      find.widgetWithText(FxLiquidPrimaryButton, 'Adicionar exercício'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Opções do treino'));
    await _settle(tester);

    expect(find.text('Atribuir a aluno'), findsOneWidget);
    expect(
      find.text('Mesmo treino: suas edições chegam ao aluno'),
      findsOneWidget,
    );
    expect(find.text('Copiar para aluno'), findsOneWidget);
    expect(
      find.text('Cópia só do aluno: o original não muda'),
      findsOneWidget,
    );
  });
}
