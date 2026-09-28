import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_error_state.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/models/treino_previa.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/screens/treino_previa_screen.dart';
import 'package:focux_app/features/dashboard/data/dashboard_repository.dart';
import 'package:focux_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

final _hoje = DateTime.now();
final _hojeCedo = DateTime(_hoje.year, _hoje.month, _hoje.day, 0, 1);

const _previa = TreinoPrevia(
  treinoId: 1,
  treinoNome: 'Treino A',
  exercicios: [
    TreinoPreviaExercicio(
      treinoExercicioId: 10,
      exercicioNome: 'Agachamento livre',
      series: 3,
      repeticoes: '10–12',
      cargaKg: 20,
      descansoSegundos: 60,
      observacoes: 'Desça devagar, joelho alinhado com o pé.',
      temVideo: true,
    ),
    TreinoPreviaExercicio(treinoExercicioId: 11, exercicioNome: 'Prancha'),
  ],
);

AlunoDashboardHomeBundle _home({
  String status = 'DISPONIVEL',
  List<Map<String, dynamic>> historico = const [],
}) => AlunoDashboardHomeBundle.fromJson({
  'aluno': {'id': 7, 'nome': 'Ana', 'email': 'a@t.com', 'status': 'ATIVO'},
  'treinos': [
    {
      'treinoId': 1,
      'treinoNome': 'Treino A',
      'status': status,
      'exercicios': [],
      'exerciciosCount': status == 'AGUARDANDO_LIBERACAO' ? 0 : 2,
    },
  ],
  'historicoResumo': historico,
  'medidas': [],
  'chat': {'possuiMensagemDoAluno': false, 'naoLidasDoPersonal': 0},
});

class _FakeCheckinRepository implements CheckinRepository {
  final confirmados = <int>[];

  @override
  Future<ExecucaoTreino> confirmarPlano(int treinoId) async {
    confirmados.add(treinoId);
    return ExecucaoTreino.fromJson({
      'id': 99,
      'treinoId': treinoId,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('disponível: prescrição real, Iniciar e Já fiz', (tester) async {
    await _pump(tester, home: _home());

    expect(find.text('Treino A'), findsWidgets);
    expect(find.text('2 exercícios'), findsOneWidget);
    expect(find.text('Agachamento livre'), findsOneWidget);
    expect(find.text('3 × 10–12 · 20 kg · descanso 60 s'), findsOneWidget);
    expect(
      find.text('Desça devagar, joelho alinhado com o pé.'),
      findsOneWidget,
    );
    expect(find.text('Com vídeo'), findsOneWidget);
    expect(find.text('Prancha'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('Já fiz este treino'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Iniciar fecha a prévia com true; nada é gravado aqui', (
    tester,
  ) async {
    final repo = _FakeCheckinRepository();
    await _pump(tester, home: _home(), repo: repo);

    await tester.tap(find.text('Iniciar treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('resultado true'), findsOneWidget);
    expect(repo.confirmados, isEmpty);
  });

  testWidgets('sessão aberta desta ficha: Continuar, sem Já fiz', (
    tester,
  ) async {
    await _pump(tester, home: _home(status: 'EM_ANDAMENTO'));

    expect(find.text('Continuar treino'), findsOneWidget);
    expect(find.text('Já fiz este treino'), findsNothing);
  });

  testWidgets('feito hoje: pode repetir, mas não registra de novo', (
    tester,
  ) async {
    await _pump(
      tester,
      home: _home(
        historico: [
          {
            'id': 91,
            'treinoId': 1,
            'treinoNome': 'Treino A',
            'status': 'CONCLUIDO',
            'iniciadoEm': _hojeCedo.toIso8601String(),
            'concluidoEm':
                _hojeCedo.add(const Duration(minutes: 40)).toIso8601String(),
          },
        ],
      ),
    );

    expect(find.text('Iniciar treino'), findsOneWidget);
    expect(find.text('Já fiz este treino'), findsNothing);
  });

  testWidgets('em preparação: sem rodapé de treino', (tester) async {
    await _pump(
      tester,
      home: _home(status: 'AGUARDANDO_LIBERACAO'),
      previa: const TreinoPrevia(
        treinoId: 1,
        treinoNome: 'Treino A',
        exercicios: [],
      ),
    );

    expect(find.text('Iniciar treino'), findsNothing);
    expect(find.text('Já fiz este treino'), findsNothing);
  });

  testWidgets('ficha fora do plano (404): mensagem e volta para Treinos', (
    tester,
  ) async {
    await _pump(
      tester,
      home: _home(),
      erro: DioException(
        requestOptions: RequestOptions(path: '/api/checkin/treinos/1/previa'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/checkin/treinos/1/previa'),
          statusCode: 404,
        ),
      ),
    );

    expect(
      find.text('Este treino não está mais no seu plano.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Voltar para Treinos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('carregando: skeleton com leitura, sem botões', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, home: _home(), pendente: true);
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('Carregando o treino'), findsOneWidget);
    expect(find.text('Iniciar treino'), findsNothing);
    expect(find.text('Já fiz este treino'), findsNothing);
    handle.dispose();
  });

  testWidgets('falha de rede: erro com tentar de novo', (tester) async {
    await _pump(tester, home: _home(), erro: Exception('offline'));

    expect(find.byType(FxErrorState), findsOneWidget);
    expect(find.text('Iniciar treino'), findsNothing);
  });

  testWidgets('Já fiz: confirma, grava sem séries e celebra', (tester) async {
    final repo = _FakeCheckinRepository();
    await _pump(tester, home: _home(), repo: repo);

    await tester.tap(find.text('Já fiz este treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Registrar sem séries?'), findsOneWidget);
    expect(repo.confirmados, isEmpty);

    await tester.tap(find.text('Registrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.confirmados, [1]);
    expect(find.text('Treino registrado'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('Já fiz: voltar no sheet não grava', (tester) async {
    final repo = _FakeCheckinRepository();
    await _pump(tester, home: _home(), repo: repo);

    await tester.tap(find.text('Já fiz este treino'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.confirmados, isEmpty);
    expect(find.text('Já fiz este treino'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required AlunoDashboardHomeBundle home,
  TreinoPrevia previa = _previa,
  Object? erro,
  _FakeCheckinRepository? repo,
  bool pendente = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/checkin/treinos',
    routes: [
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const _HubFalso(),
      ),
      GoRoute(
        path: '/checkin/treino/:id',
        builder: (context, state) => const TreinoPreviaScreen(treinoId: 1),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        alunoDashboardHomeProvider.overrideWith((ref) async => home),
        treinoPreviaProvider.overrideWith(
          (ref, id) =>
              pendente
                  ? Completer<TreinoPrevia>().future
                  : erro == null
                  ? Future.value(previa)
                  : Future.error(erro),
        ),
        checkinRepositoryProvider.overrideWithValue(
          repo ?? _FakeCheckinRepository(),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('abrir'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

class _HubFalso extends StatefulWidget {
  const _HubFalso();

  @override
  State<_HubFalso> createState() => _HubFalsoState();
}

class _HubFalsoState extends State<_HubFalso> {
  bool? _resultado;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        TextButton(
          onPressed: () async {
            final r = await context.push<bool>('/checkin/treino/1');
            if (mounted) setState(() => _resultado = r);
          },
          child: const Text('abrir'),
        ),
        if (_resultado != null) Text('resultado $_resultado'),
      ],
    ),
  );
}
