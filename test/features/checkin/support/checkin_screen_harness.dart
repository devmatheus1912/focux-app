import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/screens/checkin_screen.dart';
import 'package:focux_app/features/checkin/services/checkin_descanso_alerta.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

DioException checkinErroStatus(int code, {String? erro}) {
  final req = RequestOptions(path: '/api/checkin');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: req,
      statusCode: code,
      data: erro == null ? null : {'erro': erro},
    ),
  );
}

class FakeCheckinRepo implements CheckinRepository {
  FakeCheckinRepo({this.feitas = const [0, 0], this.rpeAlvo});

  final List<int> feitas;

  /// Com valor, Registrar pede o esforço antes de enviar.
  final int? rpeAlvo;
  bool offline = false;

  /// Lançado por `registrarSerie` enquanto não for nulo.
  Object? erroSerie;

  /// Segura a resposta de `registrarSerie` até completar.
  Completer<void>? travaSerie;

  /// Lançado por `concluir` enquanto não for nulo.
  Object? erroConcluir;
  bool concluirSemEvolucao = false;

  int registros = 0;
  int concluidos = 0;
  int descartes = 0;
  final cargas = <double?>[];
  final Map<int, int> _feitasPorTe = {};

  @override
  Future<ExecucaoTreino> iniciar(int treinoId) async =>
      ExecucaoTreino.fromJson({
        'id': 1,
        'treinoId': treinoId,
        'treinoNome': 'Treino A',
        'status': 'EM_ANDAMENTO',
        'exercicios': [
          {
            ..._exercicioJson(10, 2, 'Supino', _feitasPorTe[2] ?? feitas[0]),
            'rpeAlvo': rpeAlvo,
          },
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
    cargas.add(cargaKg);
    await travaSerie?.future;
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(path: '/series'),
        type: DioExceptionType.connectionError,
      );
    }
    final erro = erroSerie;
    if (erro != null) throw erro;
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
    final erro = erroConcluir;
    if (erro != null) throw erro;
    return ExecucaoTreino.fromJson({
      'id': execucaoId,
      'treinoId': 5,
      'treinoNome': 'Treino A',
      'status': 'CONCLUIDO',
      'exercicios': const [],
      if (!concluirSemEvolucao)
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
  Future<ExecucaoTreino> descartar(int execucaoId) async {
    descartes++;
    return ExecucaoTreino.fromJson({
      'id': execucaoId,
      'treinoId': 5,
      'treinoNome': 'Treino A',
      'status': 'CANCELADO',
      'exercicios': const [],
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDescansoAlerta implements CheckinDescansoAlerta {
  int toques = 0;

  @override
  Future<void> tocar() async => toques++;
}

class CheckinHarness {
  CheckinHarness(this.repo);

  final FakeCheckinRepo repo;
  final alerta = FakeDescansoAlerta();
  final conexao = StreamController<void>.broadcast();
  DateTime agora = DateTime(2026, 9, 28, 18);

  /// `false` simula token apagado pelo `SessionInvalidator`.
  bool sessaoAtiva = true;
}

Future<CheckinHarness> pumpCheckin(
  WidgetTester tester,
  FakeCheckinRepo repo, {
  Size tela = const Size(430, 1400),
}) async {
  final h = CheckinHarness(repo);
  addTearDown(h.conexao.close);
  await tester.binding.setSurfaceSize(tela);
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
        checkinSessaoAtivaProvider.overrideWithValue(
          () async => h.sessaoAtiva,
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
  await tester.pump(const Duration(milliseconds: 100));
  return h;
}

Future<void> pumpSheet(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> tocarRegistrar(WidgetTester tester, {bool primeira = true}) async {
  await tester.tap(find.text(primeira ? 'Registrar série' : 'Próxima série'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}
