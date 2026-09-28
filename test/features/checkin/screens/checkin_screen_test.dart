import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/screens/checkin_screen.dart';
import 'package:focux_app/features/checkin/services/checkin_descanso_alerta.dart';
import 'package:focux_app/features/checkin/widgets/checkin_serie_campos_widgets.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _exercicioJson(int id, int te, String nome, int feitas) =>
    {
      'id': id,
      'treinoExercicioId': te,
      'exercicioNome': nome,
      'series': 3,
      'repeticoes': '10',
      'cargaKg': 20.0,
      'descansoSegundos': 60,
      'seriesFeitas': feitas,
      'concluido': feitas >= 3,
    };

class _FakeRepo implements CheckinRepository {
  _FakeRepo({this.feitas = const [0, 0]});

  final List<int> feitas;
  bool offline = false;
  int registros = 0;
  int concluidos = 0;
  final Map<int, int> _feitasPorTe = {};

  @override
  Future<ExecucaoTreino> iniciar(int treinoId) async =>
      ExecucaoTreino.fromJson({
        'id': 1,
        'treinoId': treinoId,
        'treinoNome': 'Treino A',
        'status': 'EM_ANDAMENTO',
        'exercicios': [
          _exercicioJson(10, 2, 'Supino', _feitasPorTe[2] ?? feitas[0]),
          _exercicioJson(11, 3, 'Remada', _feitasPorTe[3] ?? feitas[1]),
        ],
      });

  @override
  Future<ExecucaoExercicio> registrarSerie(
    int execucaoId,
    int treinoExercicioId, {
    required int numero,
    double? cargaKg,
    String? repeticoes,
    String? feedback,
    int? rpe,
    bool? dor,
    int? presencialAlunoId,
  }) async {
    registros++;
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/series'),
        type: DioExceptionType.connectionError,
      );
    }
    _feitasPorTe[treinoExercicioId] = numero;
    return ExecucaoExercicio.fromJson(
      _exercicioJson(
        treinoExercicioId == 2 ? 10 : 11,
        treinoExercicioId,
        treinoExercicioId == 2 ? 'Supino' : 'Remada',
        numero,
      ),
    );
  }

  @override
  Future<ExecucaoTreino> concluir(
    int execucaoId, {
    int? presencialAlunoId,
  }) async {
    concluidos++;
    return ExecucaoTreino.fromJson({
      'id': execucaoId,
      'treinoId': 5,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
      'exercicios': const [],
      'evolucoesPerformance': [
        {
          'tipo': 'CARGA',
          'exercicioId': 1,
          'exercicioNome': 'Supino',
          'valorAnterior': 20,
          'valorAtual': 22.5,
          'diferenca': 2.5,
          'unidade': 'kg',
          'mensagem': 'Boa',
        },
      ],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAlerta implements CheckinDescansoAlerta {
  int toques = 0;

  @override
  Future<void> tocar() async => toques++;
}

class _Harness {
  _Harness(this.repo);

  final _FakeRepo repo;
  final alerta = _FakeAlerta();
  final conexao = StreamController<void>.broadcast();
  DateTime agora = DateTime(2026, 9, 28, 18);
}

Future<_Harness> _pump(WidgetTester tester, _FakeRepo repo) async {
  final h = _Harness(repo);
  addTearDown(h.conexao.close);
  await tester.binding.setSurfaceSize(const Size(430, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/checkin/executar',
    routes: [
      GoRoute(
        path: '/checkin/treinos',
        builder: (context, state) => const Text('treinos'),
      ),
      GoRoute(
        path: '/checkin/executar',
        builder: (context, state) => const CheckinScreen(treinoId: 5),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkinRepositoryProvider.overrideWithValue(repo),
        checkinConexaoVoltouProvider.overrideWithValue(h.conexao.stream),
        checkinDescansoAlertaProvider.overrideWithValue(h.alerta),
        checkinRelogioProvider.overrideWithValue(() => h.agora),
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
  await tester.pump(const Duration(milliseconds: 100));
  return h;
}

Future<void> _sheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _registrar(WidgetTester tester, {bool primeira = true}) async {
  await tester.tap(find.text(primeira ? 'Registrar série' : 'Próxima série'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  const fila = CheckinSeriesPendentesStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('sem conexão: série fica feita, descanso começa, aviso aparece', (
    tester,
  ) async {
    final repo = _FakeRepo()..offline = true;
    await _pump(tester, repo);

    await _registrar(tester);

    expect(find.text('Pular descanso'), findsOneWidget);
    expect(find.text('1 série esperando conexão'), findsOneWidget);
    expect((await fila.ler()).single.numero, 1);

    await tester.tap(find.text('Pular descanso'));
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('conexão volta: fila reenvia e o aviso some', (tester) async {
    final repo = _FakeRepo()..offline = true;
    final h = await _pump(tester, repo);
    await _registrar(tester);
    expect(find.text('1 série esperando conexão'), findsOneWidget);

    repo.offline = false;
    h.conexao.add(null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('1 série esperando conexão'), findsNothing);
    expect(await fila.ler(), isEmpty);
    expect(repo.registros, 2);
  });

  testWidgets('"Tentar agora" e voltar do background reenviam', (tester) async {
    final repo = _FakeRepo()..offline = true;
    await _pump(tester, repo);
    await _registrar(tester);

    await tester.tap(find.text('Tentar agora'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(repo.registros, 2);
    expect(find.text('1 série esperando conexão'), findsOneWidget);

    repo.offline = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1 série esperando conexão'), findsNothing);
  });

  testWidgets('abrir a execução reenvia a fila salva no aparelho', (
    tester,
  ) async {
    await fila.adicionar(
      const CheckinSeriePendente(
        execucaoId: 1,
        treinoExercicioId: 2,
        numero: 1,
        cargaKg: 20,
        repeticoes: '10',
      ),
    );
    final repo = _FakeRepo();
    await _pump(tester, repo);

    expect(repo.registros, 1);
    expect(await fila.ler(), isEmpty);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('finalizar com série pendente avisa e não conclui', (
    tester,
  ) async {
    final repo = _FakeRepo()..offline = true;
    await _pump(tester, repo);
    await _registrar(tester);
    await tester.tap(find.text('Pular descanso'));
    await tester.pump();

    await tester.tap(find.text('Finalizar treino'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Conecte-se para enviar as séries pendentes antes de continuar.',
      ),
      findsOneWidget,
    );
    expect(repo.concluidos, 0);
  });

  testWidgets('finalizar incompleto pede confirmação', (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);

    await tester.tap(find.text('Finalizar treino'));
    await _sheet(tester);
    expect(find.text('Faltam 2 exercícios'), findsOneWidget);
    await tester.tap(find.text('Voltar ao treino'));
    await _sheet(tester);
    expect(repo.concluidos, 0);

    await tester.tap(find.text('Finalizar treino'));
    await _sheet(tester);
    await tester.tap(find.text('Finalizar'));
    await _sheet(tester);
    expect(repo.concluidos, 1);

    await tester.tap(find.text('Continuar'));
    await _sheet(tester);
    expect(find.text('treinos'), findsOneWidget);
  });

  testWidgets('"Encerrar agora" também confirma quando falta exercício', (
    tester,
  ) async {
    final repo = _FakeRepo(feitas: [3, 1]);
    await _pump(tester, repo);

    await tester.tap(find.text('Sair'));
    await _sheet(tester);
    await tester.tap(find.text('Encerrar agora'));
    await _sheet(tester);

    expect(find.text('Falta 1 exercício'), findsOneWidget);
    expect(repo.concluidos, 0);
  });

  testWidgets('tudo feito finaliza sem confirmação', (tester) async {
    final repo = _FakeRepo(feitas: [3, 3]);
    await _pump(tester, repo);

    await tester.tap(find.text('Finalizar treino'));
    await _sheet(tester);

    expect(find.textContaining('Falta'), findsNothing);
    expect(repo.concluidos, 1);
    await tester.tap(find.text('Continuar'));
    await _sheet(tester);
  });

  testWidgets('fim do descanso com app aberto toca e volta à série', (
    tester,
  ) async {
    final repo = _FakeRepo();
    final h = await _pump(tester, repo);
    await _registrar(tester);
    expect(find.text('Pular descanso'), findsOneWidget);

    h.agora = h.agora.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));

    expect(h.alerta.toques, 1);
    expect(find.text('Pular descanso'), findsNothing);
    expect(find.text('Próxima série'), findsOneWidget);
  });

  testWidgets('pular ou voltar do background não toca', (tester) async {
    final repo = _FakeRepo();
    final h = await _pump(tester, repo);
    await _registrar(tester);
    await tester.tap(find.text('Pular descanso'));
    await tester.pump(const Duration(seconds: 2));
    expect(h.alerta.toques, 0);

    await _registrar(tester, primeira: false);
    expect(find.text('Pular descanso'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    h.agora = h.agora.add(const Duration(seconds: 61));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    expect(h.alerta.toques, 0);
    expect(find.text('Pular descanso'), findsNothing);
  });

  testWidgets('chip de sensação tem 48 dp de alvo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CheckinFeedbackChip(
              label: 'Ok',
              selected: false,
              color: Colors.teal,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(CheckinFeedbackChip));
    expect(size.height, greaterThanOrEqualTo(checkinFeedbackChipMin));
    expect(size.width, greaterThanOrEqualTo(checkinFeedbackChipMin));
  });
}
