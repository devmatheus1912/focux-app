import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/screens/historico_detalhe_screen.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final _inicio = DateTime(2026, 9, 23, 7);

ExecucaoTreino _execucao({
  String status = 'CONCLUIDO',
  int treinoId = 1,
  String nome = 'Treino A',
  bool comNota = true,
}) => ExecucaoTreino.fromJson({
  'id': 90,
  'treinoId': treinoId,
  'treinoNome': nome,
  'status': status,
  'iniciadoEm': _inicio.toIso8601String(),
  if (status == 'CONCLUIDO')
    'concluidoEm': _inicio.add(const Duration(minutes: 48)).toIso8601String(),
  'exercicios': [
    {
      'exercicioNome': 'Supino',
      'series': 3,
      'seriesFeitas': 3,
      'seriesDetalhes': [
        {'cargaKg': 20.0, 'repeticoes': '10'},
        {'cargaKg': 20.0, 'repeticoes': '10'},
        {'cargaKg': 22.5, 'repeticoes': '8'},
      ],
    },
    {
      'exercicioNome': 'Remada',
      'series': 4,
      'seriesFeitas': 1,
      if (comNota) 'observacoes': 'Pegada neutra',
      'seriesDetalhes': [
        {'cargaKg': 30.0, 'repeticoes': '12'},
      ],
    },
  ],
});

AlunoDashboardHomeBundle _home(List<int> fichas) =>
    AlunoDashboardHomeBundle.fromJson({
      'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
      'treinos': [
        for (final id in fichas)
          {
            'treinoId': id,
            'treinoNome': 'Treino $id',
            'status': 'DISPONIVEL',
            'exercicios': [],
            'exerciciosCount': 2,
          },
      ],
      'historicoResumo': [],
      'medidas': [],
      'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
    });

DioException _http(int status) => DioException(
  requestOptions: RequestOptions(path: '/api/checkin/90'),
  response: Response(
    requestOptions: RequestOptions(path: '/api/checkin/90'),
    statusCode: status,
  ),
);

class _FakeCheckinRepository implements CheckinRepository {
  _FakeCheckinRepository({this.execucao, this.erro, this.evolucao});

  final ExecucaoTreino? execucao;
  final Object? erro;
  final SessaoEvolucaoDto? evolucao;

  @override
  Future<ExecucaoTreino> detalhe(int execucaoId) async {
    if (erro case final e?) throw e;
    return execucao ?? Completer<ExecucaoTreino>().future;
  }

  @override
  Future<SessaoEvolucaoDto> evolucaoSessao(int execucaoId) async {
    if (evolucao case final e?) return e;
    throw Exception('sem evolução');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('concluída: resumo, números fixos e uma rolagem sem abas', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCheckinRepository(
        execucao: _execucao(),
        evolucao: SessaoEvolucaoDto.fromJson({
          'volumeKg': 1200.0,
          'seriesFeitas': 4,
          'seriesPlanejadas': 7,
          'sinal': 'MELHOROU',
        }),
      ),
    );

    expect(find.text('Treino A'), findsWidgets);
    expect(find.textContaining('Concluído · '), findsOneWidget);
    expect(find.text('Concluído'), findsOneWidget);
    expect(find.text('48 min'), findsOneWidget);
    expect(find.text('Volume acima da sessão anterior'), findsOneWidget);
    expect(find.text('1,2 mil kg'), findsOneWidget);
    expect(find.text('4 de 7'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Recordes'), findsNothing);
    expect(find.text('Sinal'), findsNothing);
    expect(find.text('Treinar de novo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem notas nem recordes: seções somem', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository(execucao: _execucao(comNota: false)),
    );

    expect(find.text('Exercícios'), findsWidgets);
    expect(find.text('Notas'), findsNothing);
    expect(find.text('Recordes'), findsNothing);
  });

  testWidgets('Treinar de novo abre a prévia da ficha', (tester) async {
    await _pump(tester, _FakeCheckinRepository(execucao: _execucao()));

    await tester.tap(find.text('Treinar de novo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('previa 1'), findsOneWidget);
    expect(find.text('executar 1'), findsNothing);
  });

  testWidgets('ficha fora do plano: sem Treinar de novo', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository(execucao: _execucao(treinoId: 9)),
    );

    expect(find.text('Treinar de novo'), findsNothing);
    expect(find.text('Continuar treino'), findsNothing);
  });

  testWidgets('sessão aberta: Continuar treino leva à execução', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCheckinRepository(execucao: _execucao(status: 'EM_ANDAMENTO')),
    );

    expect(find.text('Em andamento'), findsWidgets);
    await tester.tap(find.text('Continuar treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('executar 1'), findsOneWidget);
  });

  testWidgets('404: sessão não encontrada com volta ao histórico', (
    tester,
  ) async {
    await _pump(tester, _FakeCheckinRepository(erro: _http(404)));

    expect(find.text('Sessão não encontrada'), findsOneWidget);
    await tester.tap(find.text('Voltar ao histórico'));
    await tester.pumpAndSettle();
    expect(find.text('historico'), findsOneWidget);
  });

  testWidgets('falha: erro com tentar de novo', (tester) async {
    await _pump(tester, _FakeCheckinRepository(erro: _http(500)));

    expect(find.byType(FxErrorState), findsOneWidget);
  });

  testWidgets('carregando: skeleton com leitura própria', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _FakeCheckinRepository());
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('Carregando a sessão'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('fonte 2x em tela estreita não estoura', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository(
        execucao: _execucao(nome: 'Treino de força para membros inferiores'),
        evolucao: SessaoEvolucaoDto.fromJson({
          'volumeKg': 1200.0,
          'seriesFeitas': 4,
          'seriesPlanejadas': 7,
          'sinal': 'PRIMEIRA',
        }),
      ),
      size: const Size(320, 2400),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCheckinRepository repo, {
  Size size = const Size(430, 2400),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/checkin/historico/90',
    routes: [
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const Text('historico'),
      ),
      GoRoute(
        path: '/checkin/historico/:id',
        builder:
            (context, state) => HistoricoDetalheScreen(
              execucaoId: int.parse(state.pathParameters['id']!),
            ),
      ),
      GoRoute(
        path: '/checkin/treino/:id',
        builder:
            (context, state) => Text('previa ${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) => Text('executar ${state.extra}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkinRepositoryProvider.overrideWithValue(repo),
        alunoDashboardHomeProvider.overrideWith(
          (ref) => Future.value(_home([1, 2])),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}
