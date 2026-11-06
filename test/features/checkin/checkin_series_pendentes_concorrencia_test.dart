import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:shared_preferences/shared_preferences.dart';

CheckinSeriePendente _serie(int numero) => CheckinSeriePendente(
  execucaoId: 1,
  treinoExercicioId: 10,
  numero: numero,
  cargaKg: 20,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('série marcada enquanto a fila remove outra não se perde', () async {
    const store = CheckinSeriesPendentesStore();
    await store.adicionar(_serie(1));
    await store.adicionar(_serie(2));

    // A rodada da fila tira a 1 (enviada) e o aluno marca a 3 ao mesmo tempo.
    await Future.wait([store.remover(_serie(1)), store.adicionar(_serie(3))]);

    final fila = await store.ler();
    expect(fila.map((s) => s.numero), [2, 3]);
  });

  test('várias escritas simultâneas ficam todas na fila', () async {
    const store = CheckinSeriesPendentesStore();
    await Future.wait([
      for (var n = 1; n <= 5; n++) store.adicionar(_serie(n)),
    ]);

    // Nenhuma se perde; a ordem de chegada no mesmo instante não importa
    // (cada série leva o próprio número).
    expect(
      (await store.ler()).map((s) => s.numero),
      unorderedEquals([1, 2, 3, 4, 5]),
    );
  });
}
