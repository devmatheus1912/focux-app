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

  test('erro de conexão enfileira; resposta do servidor não', () {
    expect(checkinErroDeConexao(_rede()), isTrue);
    expect(
      checkinErroDeConexao(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.receiveTimeout,
        ),
      ),
      isTrue,
    );
    expect(checkinErroDeConexao(_status(400)), isFalse);
    expect(checkinErroDeConexao(_status(500)), isFalse);
    expect(checkinErroDeConexao(StateError('x')), isFalse);
  });

  test('5xx, 401 e 429 são transitórios; 400 e 404 não', () {
    expect(checkinErroTransitorio(_rede()), isTrue);
    expect(checkinErroTransitorio(_status(503)), isTrue);
    expect(checkinErroTransitorio(_status(401)), isTrue);
    expect(checkinErroTransitorio(_status(429)), isTrue);
    expect(checkinErroTransitorio(_status(400)), isFalse);
    expect(checkinErroTransitorio(_status(404)), isFalse);
  });

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

  test('json corrompido vira fila vazia', () async {
    SharedPreferences.setMockInitialValues({
      CheckinSeriesPendentesStore.prefKey: '{quebrado',
    });
    expect(await store.ler(), isEmpty);
  });
}
