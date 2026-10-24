import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/api_client.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/features/treinos/data/ficha_historico_repository.dart';
import 'package:focux_app/features/treinos/models/ficha_historico.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';
import 'package:focux_app/features/treinos/providers/ficha_historico_provider.dart';
import 'package:focux_app/features/treinos/screens/ficha_anterior_screen.dart';
import 'package:focux_app/features/treinos/screens/fichas_anteriores_screen.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class RepoHistoricoFalso extends FichaHistoricoRepository {
  RepoHistoricoFalso(this.fichas) : super(ApiClient());

  List<FichaHistorico> fichas;
  final usadas = <(int, int, bool)>[];
  List<String> semSessao = const [];

  @override
  Future<List<FichaHistorico>> listar(int alunoId) async => fichas;

  @override
  Future<FichaHistorico> buscar(int alunoId, int fichaId) async =>
      fichas.firstWhere((f) => f.id == fichaId);

  @override
  Future<UsoDaFichaAnterior> usar(
    int alunoId,
    int fichaId, {
    bool manterCargas = true,
  }) async {
    usadas.add((alunoId, fichaId, manterCargas));
    return UsoDaFichaAnterior(rotina: RotinaFila.vazia, semSessao: semSessao);
  }
}

final fichaRecomecada = FichaHistorico(
  id: 7,
  motivo: MotivoTroca.recomecada,
  vigenciaInicio: DateTime(2026, 8, 12),
  vigenciaFim: DateTime(2026, 10, 14),
  encerradaEm: DateTime(2026, 10, 14, 9),
  sessoes: 2,
  exercicios: 9,
  itens: const [
    FichaHistoricoItem(
      descanso: false,
      treinoId: 1,
      nome: 'Treino A',
      diaSemana: 1,
      exerciciosCount: 5,
      disponivel: true,
    ),
    FichaHistoricoItem(descanso: true),
    FichaHistoricoItem(
      descanso: false,
      treinoId: 2,
      nome: 'Treino B',
      diaSemana: 3,
      exerciciosCount: 4,
    ),
  ],
);

final fichaDoModelo = FichaHistorico(
  id: 6,
  motivo: MotivoTroca.modelo,
  nomeModelo: 'Hipertrofia 4 dias',
  encerradaEm: DateTime(2026, 8, 11, 9),
  sessoes: 1,
  exercicios: 6,
  itens: const [
    FichaHistoricoItem(
      descanso: false,
      treinoId: 3,
      nome: 'Treino C',
      diaSemana: 2,
      exerciciosCount: 6,
      disponivel: true,
    ),
  ],
);

Future<void> assentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<RepoHistoricoFalso> abrirHistorico(
  WidgetTester tester,
  List<FichaHistorico> fichas, {
  String destino = '/alunos/3/fichas-anteriores',
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final repo = RepoHistoricoFalso(fichas);
  final router = GoRouter(
    initialLocation: '/inicio',
    routes: [
      GoRoute(
        path: '/inicio',
        builder: (context, state) => const Scaffold(body: Text('inicio')),
      ),
      GoRoute(
        path: '/alunos/:id/fichas-anteriores',
        builder:
            (context, state) =>
                const FichasAnterioresScreen(alunoId: 3, alunoNome: 'Ana'),
      ),
      GoRoute(
        path: '/alunos/:id/fichas-anteriores/:fichaId',
        builder:
            (context, state) => FichaAnteriorScreen(
              alunoId: 3,
              alunoNome: 'Ana',
              fichaId: int.parse(state.pathParameters['fichaId']!),
            ),
      ),
      GoRoute(
        path: '/treinos/:id',
        builder: (context, state) => const Scaffold(body: Text('montador')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [fichaHistoricoRepositoryProvider.overrideWithValue(repo)],
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
  router.push(destino);
  await assentar(tester);
  return repo;
}
