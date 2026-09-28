import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/api/pagina.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/screens/historico_screen.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final _hoje = DateTime.now();
final _hojeCedo = DateTime(_hoje.year, _hoje.month, _hoje.day, 0, 1);

ExecucaoTreino _sessao(
  int id,
  String nome, {
  int treinoId = 1,
  int diasAtras = 0,
}) {
  final inicio = _hojeCedo.subtract(Duration(days: diasAtras));
  return ExecucaoTreino.fromJson({
    'id': id,
    'treinoId': treinoId,
    'treinoNome': nome,
    'status': 'CONCLUIDO',
    'iniciadoEm': inicio.toIso8601String(),
    'concluidoEm': inicio.add(const Duration(minutes: 52)).toIso8601String(),
    'exerciciosConcluidos': 6,
  });
}

Pagina<ExecucaoTreino> _pagina(
  List<ExecucaoTreino> sessoes, {
  String? proximo,
}) => Pagina(content: sessoes, hasNext: proximo != null, nextCursor: proximo);

AlunoDashboardHomeBundle _home(List<(int, String)> fichas) =>
    AlunoDashboardHomeBundle.fromJson({
      'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
      'treinos': [
        for (final (id, nome) in fichas)
          {
            'treinoId': id,
            'treinoNome': nome,
            'status': 'DISPONIVEL',
            'exercicios': [],
            'exerciciosCount': 6,
          },
      ],
      'historicoResumo': [],
      'medidas': [],
      'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
    });

/// Respostas por (treinoId, cursor). Com mais de uma na fila, cada chamada
/// consome a primeira: dá para simular falha seguida de sucesso.
class _FakeCheckinRepository implements CheckinRepository {
  _FakeCheckinRepository(this.respostas, {this.pendente = false});

  final Map<(int?, String?), List<Object>> respostas;
  final bool pendente;
  final chamadas = <(int?, String?)>[];

  @override
  Future<Pagina<ExecucaoTreino>> historicoConcluidos({
    String? cursor,
    int? treinoId,
    int size = 20,
  }) async {
    if (pendente) return Completer<Pagina<ExecucaoTreino>>().future;
    chamadas.add((treinoId, cursor));
    final fila = respostas[(treinoId, cursor)];
    if (fila == null || fila.isEmpty) throw Exception('offline');
    final r = fila.length > 1 ? fila.removeAt(0) : fila.first;
    if (r is Pagina<ExecucaoTreino>) return r;
    throw r;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('agrupa por semana com contagem e linha igual ao hub', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [
          _pagina([
            _sessao(3, 'Treino B', treinoId: 2),
            _sessao(2, 'Treino A'),
            _sessao(1, 'Treino C', treinoId: 3, diasAtras: 7),
          ]),
        ],
      }),
    );

    expect(find.text('Histórico'), findsWidgets);
    expect(find.text('Esta semana · 2 treinos'), findsOneWidget);
    expect(find.text('Semana passada · 1 treino'), findsOneWidget);
    expect(find.text('Hoje · 52 min'), findsNWidgets(2));
    expect(find.text('Treino C'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
    expect(find.text('Em andamento'), findsNothing);
    expect(
      tester.getTopLeft(find.text('Esta semana · 2 treinos')).dy,
      lessThan(tester.getTopLeft(find.text('Semana passada · 1 treino')).dy),
    );
  });

  testWidgets('chips de ficha filtram pela ficha escolhida', (tester) async {
    final repo = _FakeCheckinRepository({
      (null, null): [
        _pagina([_sessao(2, 'Treino B', treinoId: 2), _sessao(1, 'Treino A')]),
      ],
      (2, null): [
        _pagina([_sessao(2, 'Treino B', treinoId: 2)]),
      ],
    });
    await _pump(tester, repo, home: _home([(1, 'Treino A'), (2, 'Treino B')]));

    expect(find.text('Todos'), findsOneWidget);
    await tester.tap(find.widgetWithText(InkWell, 'Treino B').first);
    await _settle(tester);

    expect(repo.chamadas.last, (2, null));
    expect(find.text('Esta semana · 1 treino'), findsOneWidget);
    expect(find.text('Treino A'), findsOneWidget);
  });

  testWidgets('uma ficha só: sem chips', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [
          _pagina([_sessao(1, 'Treino A')]),
        ],
      }),
      home: _home([(1, 'Treino A')]),
    );

    expect(find.text('Todos'), findsNothing);
  });

  testWidgets('filtro sem sessões: vazio com volta para todos', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [
          _pagina([_sessao(1, 'Treino A')]),
        ],
        (2, null): [_pagina(const [])],
      }),
      home: _home([(1, 'Treino A'), (2, 'Treino B')]),
    );

    await tester.tap(find.text('Treino B'));
    await _settle(tester);
    expect(find.text('Nenhuma sessão de Treino B'), findsOneWidget);

    await tester.tap(find.text('Ver todos'));
    await _settle(tester);
    expect(find.text('Esta semana · 1 treino'), findsOneWidget);
  });

  testWidgets('sem nenhum treino: vazio leva aos treinos', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [_pagina(const [])],
      }),
    );

    expect(find.text('Nenhum treino concluído ainda'), findsOneWidget);
    await tester.tap(find.text('Ver treinos'));
    await tester.pumpAndSettle();
    expect(find.text('treinos'), findsOneWidget);
  });

  testWidgets('rolagem infinita: próxima página chega sozinha', (tester) async {
    final repo = _FakeCheckinRepository({
      (null, null): [
        _pagina([_sessao(2, 'Treino A')], proximo: 'c1'),
      ],
      (null, 'c1'): [
        _pagina([_sessao(1, 'Treino C', treinoId: 3, diasAtras: 7)]),
      ],
    });
    await _pump(tester, repo);

    expect(repo.chamadas, [(null, null), (null, 'c1')]);
    expect(find.text('Treino C'), findsOneWidget);
    expect(find.text('Semana passada · 1 treino'), findsOneWidget);
  });

  testWidgets('falha na próxima página: mantém a lista e tenta de novo', (
    tester,
  ) async {
    final repo = _FakeCheckinRepository({
      (null, null): [
        _pagina([_sessao(2, 'Treino A')], proximo: 'c1'),
      ],
      (null, 'c1'): [
        Exception('offline'),
        _pagina([_sessao(1, 'Treino C', treinoId: 3, diasAtras: 7)]),
      ],
    });
    await _pump(tester, repo);

    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('Não deu para carregar mais treinos.'), findsOneWidget);
    expect(find.text('Esta semana'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await _settle(tester);
    expect(find.text('Treino C'), findsOneWidget);
    expect(find.text('Não deu para carregar mais treinos.'), findsNothing);
  });

  testWidgets('carregando: skeleton com leitura própria', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, _FakeCheckinRepository(const {}, pendente: true));
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('Carregando o histórico'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('falha no primeiro carregamento: erro com tentar de novo', (
    tester,
  ) async {
    await _pump(tester, _FakeCheckinRepository(const {}));

    expect(find.byType(FxErrorState), findsOneWidget);
  });

  testWidgets('toque na linha abre a própria sessão', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [
          _pagina([
            _sessao(91, 'Treino A'),
            _sessao(90, 'Treino A', diasAtras: 1),
          ]),
        ],
      }),
    );

    await tester.tap(find.text('Treino A').last);
    await tester.pumpAndSettle();
    expect(find.text('detalhe 90'), findsOneWidget);
  });

  testWidgets('fonte 2x em tela estreita não estoura', (tester) async {
    await _pump(
      tester,
      _FakeCheckinRepository({
        (null, null): [
          _pagina([
            _sessao(1, 'Treino de força para membros inferiores e core'),
            _sessao(2, 'Treino B', treinoId: 2, diasAtras: 14),
          ]),
        ],
      }),
      home: _home([
        (1, 'Treino de força para membros inferiores e core'),
        (2, 'Treino B'),
      ]),
      size: const Size(320, 2400),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCheckinRepository repo, {
  AlunoDashboardHomeBundle? home,
  Size size = const Size(430, 2400),
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/checkin/historico',
    routes: [
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const Text('treinos'),
      ),
      GoRoute(
        path: '/checkin/historico',
        builder: (context, state) => const HistoricoCheckinScreen(),
      ),
      GoRoute(
        path: '/checkin/historico/:id',
        builder:
            (context, state) => Text('detalhe ${state.pathParameters['id']}'),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkinRepositoryProvider.overrideWithValue(repo),
        alunoDashboardHomeProvider.overrideWith(
          (ref) => Future.value(home ?? _home([(1, 'Treino A')])),
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
  await _settle(tester);
}
