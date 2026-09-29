import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/utils/checkin_series_fila.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException _rede() => DioException(
  requestOptions: RequestOptions(path: '/api/checkin/1/exercicio/2/series'),
  type: DioExceptionType.connectionError,
);

DioException _status(int code) {
  final req = RequestOptions(path: '/api/checkin/1/exercicio/2/series');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: req, statusCode: code),
  );
}

CheckinSeriePendente _serie(int numero, {int execucao = 1, double? carga}) =>
    CheckinSeriePendente(
      execucaoId: execucao,
      treinoExercicioId: 2,
      numero: numero,
      cargaKg: carga ?? 20,
      repeticoes: '10',
    );

ExecucaoExercicio _exercicio(int feitas) => ExecucaoExercicio(
  id: 7,
  treinoExercicioId: 2,
  exercicioNome: 'Supino',
  series: 3,
  seriesFeitas: feitas,
  concluido: false,
);

void main() {
  const store = CheckinSeriesPendentesStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a mesma série substitui a anterior e a fila persiste', () async {
    await store.adicionar(_serie(1, carga: 20));
    await store.adicionar(_serie(2));
    await store.adicionar(_serie(1, carga: 22.5));
    final fila = await store.ler();
    expect(fila.map((p) => p.numero), [2, 1]);
    expect(fila.last.cargaKg, 22.5);
  });

  test('remover não apaga versão nova registrada durante o envio', () async {
    await store.adicionar(_serie(1, carga: 20));
    await store.adicionar(_serie(1, carga: 25));
    await store.remover(_serie(1, carga: 20));
    final fila = await store.ler();
    expect(fila.single.cargaKg, 25);
  });

  test('descartar a execução tira só as séries dela', () async {
    await store.adicionar(_serie(1));
    await store.adicionar(_serie(1, execucao: 9));
    await store.removerDaExecucao(1);
    expect((await store.ler()).single.execucaoId, 9);
  });

  test('envia em ordem e para no primeiro erro de rede', () async {
    await store.adicionar(_serie(1));
    await store.adicionar(_serie(2));
    await store.adicionar(_serie(3));
    final enviadas = <int>[];
    final r = await checkinEnviarFila(
      store: store,
      enviar: (p) async {
        if (p.numero == 2) throw _rede();
        enviadas.add(p.numero);
        return _exercicio(p.numero);
      },
    );
    expect(enviadas, [1]);
    expect(r.enviadas.single.exercicio.seriesFeitas, 1);
    expect(r.rejeitadas, 0);
    expect(r.restantes.map((p) => p.numero), [2, 3]);
  });

  test('recusa do servidor tira da fila e segue', () async {
    await store.adicionar(_serie(1));
    await store.adicionar(_serie(2));
    final r = await checkinEnviarFila(
      store: store,
      enviar: (p) async {
        if (p.numero == 1) throw _status(400);
        return _exercicio(p.numero);
      },
    );
    expect(r.rejeitadas, 1);
    expect(r.enviadas.single.exercicio.seriesFeitas, 2);
    expect(r.restantes, isEmpty);
  });

  test('5xx mantém a série para a próxima tentativa', () async {
    await store.adicionar(_serie(1));
    final r = await checkinEnviarFila(
      store: store,
      enviar: (_) async => throw _status(503),
    );
    expect(r.rejeitadas, 0);
    expect(r.restantes.single.numero, 1);
  });

  group('registrar série nova', () {
    Future<CheckinRegistro> registrar(
      Object? erro, {
      List<bool> sessao = const [true],
    }) {
      var consulta = 0;
      return checkinRegistrarSerie(
        serie: _serie(1),
        store: store,
        enviar: (p) async {
          if (erro != null) throw erro;
          return _exercicio(p.numero);
        },
        sessaoAtiva:
            () async => sessao[(consulta++).clamp(0, sessao.length - 1)],
      );
    }

    test('2xx salva e não mexe na fila', () async {
      final r = await registrar(null);
      expect(r, isA<CheckinRegistroSalvo>());
      expect((r as CheckinRegistroSalvo).exercicio.seriesFeitas, 1);
      expect(await store.ler(), isEmpty);
    });

    for (final (nome, erro) in [
      ('sem conexão', _rede()),
      (
        'timeout',
        DioException(
          requestOptions: RequestOptions(path: '/series'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      ('500', _status(500)),
      ('503', _status(503)),
      ('429', _status(429)),
    ]) {
      test('$nome vai para a fila', () async {
        final r = await registrar(erro);
        expect(r, isA<CheckinRegistroNaFila>());
        expect((r as CheckinRegistroNaFila).fila.single.numero, 1);
        expect((await store.ler()).single.numero, 1);
      });
    }

    for (final code in [400, 422]) {
      test('$code é recusa: erro e nada na fila', () async {
        final r = await registrar(_status(code));
        expect(r, isA<CheckinRegistroRecusado>());
        expect(await store.ler(), isEmpty);
      });
    }

    test('401 com sessão invalidada é recusa e nada fica no aparelho', () async {
      final r = await registrar(_status(401), sessao: const [false]);
      expect(r, isA<CheckinRegistroRecusado>());
      expect(await store.ler(), isEmpty);
    });

    test('401 com token ainda presente (refresh falhou por rede) vai para a fila',
        () async {
      final r = await registrar(_status(401));
      expect(r, isA<CheckinRegistroNaFila>());
      expect((await store.ler()).single.numero, 1);
    });

    test('logout durante a gravação tira a série do aparelho', () async {
      final r = await registrar(_status(503), sessao: const [false]);
      expect(r, isA<CheckinRegistroRecusado>());
      expect(await store.ler(), isEmpty);
    });
  });

  test('json corrompido vira fila vazia', () async {
    SharedPreferences.setMockInitialValues({
      CheckinSeriesPendentesStore.prefKey: '{quebrado',
    });
    expect(await store.ler(), isEmpty);
  });
}
