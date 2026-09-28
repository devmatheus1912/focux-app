import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/auth/providers/auth_provider.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/providers/checkin_provider.dart';
import 'package:focux_app/features/checkin/widgets/checkin_fila_sync_scope.dart';
import 'package:focux_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends AuthNotifier {
  _FakeAuth(this.inicial);

  final AuthStatus inicial;

  @override
  AuthStatus build() => inicial;

  void entrar() => state = AuthStatus.authenticated;
}

enum _Modo { ok, offline, recusa }

class _FakeRepo implements CheckinRepository {
  _Modo modo = _Modo.ok;
  int envios = 0;

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
    envios++;
    final req = RequestOptions(path: '/series');
    switch (modo) {
      case _Modo.offline:
        throw DioException(
          requestOptions: req,
          type: DioExceptionType.connectionError,
        );
      case _Modo.recusa:
        throw DioException(
          requestOptions: req,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: req, statusCode: 404),
        );
      case _Modo.ok:
        return ExecucaoExercicio.fromJson({
          'id': 10,
          'treinoExercicioId': treinoExercicioId,
          'exercicioNome': 'Supino',
          'series': 3,
          'seriesFeitas': numero,
          'concluido': false,
        });
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _fila = CheckinSeriesPendentesStore();

Future<void> _enfileirar() => _fila.adicionar(
  const CheckinSeriePendente(
    execucaoId: 1,
    treinoExercicioId: 2,
    numero: 1,
    cargaKg: 20,
    repeticoes: '10',
  ),
);

Future<({_FakeAuth auth, StreamController<void> conexao})> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  AuthStatus status = AuthStatus.authenticated,
}) async {
  final auth = _FakeAuth(status);
  final conexao = StreamController<void>.broadcast();
  addTearDown(conexao.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        checkinRepositoryProvider.overrideWithValue(repo),
        checkinConexaoVoltouProvider.overrideWithValue(conexao.stream),
        authProvider.overrideWith(() => auth),
      ],
      child: MaterialApp(
        locale: const Locale('pt'),
        supportedLocales: S.supportedLocales,
        localizationsDelegates: S.localizationsDelegates,
        builder: (context, child) => CheckinFilaSyncScope(child: child!),
        home: const Scaffold(body: Text('hoje')),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
  return (auth: auth, conexao: conexao);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('logado com fila salva: reenvia ao abrir o app', (tester) async {
    await _enfileirar();
    final repo = _FakeRepo();
    await _pump(tester, repo);

    expect(repo.envios, 1);
    expect(await _fila.ler(), isEmpty);
  });

  testWidgets('fila vazia não chama o servidor', (tester) async {
    final repo = _FakeRepo();
    await _pump(tester, repo);
    expect(repo.envios, 0);
  });

  testWidgets('deslogado espera o login para reenviar', (tester) async {
    await _enfileirar();
    final repo = _FakeRepo();
    final h = await _pump(tester, repo, status: AuthStatus.unknown);
    expect(repo.envios, 0);

    h.auth.entrar();
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.envios, 1);
    expect(await _fila.ler(), isEmpty);
  });

  testWidgets('conexão volta e o app voltando do background reenviam', (
    tester,
  ) async {
    await _enfileirar();
    final repo = _FakeRepo()..modo = _Modo.offline;
    final h = await _pump(tester, repo);
    expect(repo.envios, 1);
    expect(await _fila.ler(), hasLength(1));

    h.conexao.add(null);
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.envios, 2);

    repo.modo = _Modo.ok;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 50));
    expect(repo.envios, 3);
    expect(await _fila.ler(), isEmpty);
  });

  testWidgets('série recusada sai da fila e o aluno é avisado', (tester) async {
    await _enfileirar();
    final repo = _FakeRepo()..modo = _Modo.recusa;
    await _pump(tester, repo);
    await tester.pump(const Duration(milliseconds: 300));

    expect(await _fila.ler(), isEmpty);
    expect(find.text('Uma série não foi salva. Registre de novo.'), findsOne);
  });
}
