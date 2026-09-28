import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/data/checkin_series_pendentes.dart';
import 'package:focux_app/features/checkin/utils/checkin_execucao_estado.dart';
import 'package:focux_app/features/checkin/utils/checkin_serie_input.dart';

ExecucaoExercicio _ee({
  int id = 10,
  int te = 2,
  int feitas = 0,
  bool concluido = false,
  List<ExecucaoSerie> detalhes = const [],
}) => ExecucaoExercicio(
  id: id,
  treinoExercicioId: te,
  exercicioNome: 'Supino',
  series: 3,
  seriesFeitas: feitas,
  concluido: concluido,
  seriesDetalhes: detalhes,
);

ExecucaoTreino _treino(List<ExecucaoExercicio> exercicios) => ExecucaoTreino(
  id: 1,
  treinoId: 5,
  treinoNome: 'Treino A',
  status: 'EM_ANDAMENTO',
  exercicios: exercicios,
);

CheckinSeriePendente _p(int numero, {int te = 2, int execucao = 1}) =>
    CheckinSeriePendente(
      execucaoId: execucao,
      treinoExercicioId: te,
      numero: numero,
      cargaKg: 30,
      repeticoes: '8',
    );

void main() {
  test('cronômetro retoma do início salvo e zera sessão zumbi', () {
    final agora = DateTime(2026, 9, 28, 18);
    final inicio = agora.subtract(const Duration(minutes: 20));
    expect(
      checkinInicioCronometro(inicio.toUtc().toIso8601String(), agora),
      inicio,
    );
    expect(checkinInicioCronometro(null, agora), agora);
    expect(checkinInicioCronometro('lixo', agora), agora);
    final velho = agora.subtract(const Duration(hours: 9));
    expect(
      checkinInicioCronometro(velho.toUtc().toIso8601String(), agora),
      agora,
    );
  });

  test('rascunho do stepper vale só para a próxima série', () {
    final r = CheckinRascunhos();
    final ee = ExecucaoExercicio(
      id: 10,
      treinoExercicioId: 2,
      exercicioNome: 'Supino',
      series: 3,
      seriesFeitas: 0,
      concluido: false,
      cargaKg: 20,
      repeticoes: '10',
    );
    r.somarCarga(ee, 2.5);
    r.somarReps(ee, -1);
    expect(r.de(ee).cargaKg, 22.5);
    expect(r.de(ee).reps, 9);
    r.somarCarga(ee, -100);
    expect(r.de(ee).cargaKg, 0);
    expect(r.de(ee.copyWith(seriesFeitas: 1)).cargaKg, 20);
  });

  test('série pendente conta como feita e entra nos detalhes', () {
    final depois = checkinAplicarSerieLocal(
      _ee(feitas: 1, detalhes: const [ExecucaoSerie(id: 4, numero: 1)]),
      _p(2),
    );
    expect(depois.seriesFeitas, 2);
    expect(depois.concluido, isFalse);
    expect(depois.seriesDetalhes.map((s) => s.numero), [1, 2]);
    expect(depois.seriesDetalhes.last.cargaKg, 30);
  });

  test('última série pendente conclui o exercício', () {
    final depois = checkinAplicarSerieLocal(_ee(feitas: 2), _p(3));
    expect(depois.concluido, isTrue);
  });

  test('reaplica só a fila desta execução', () {
    final treino = _treino([_ee(), _ee(id: 11, te: 3)]);
    final atual = checkinAplicarPendentes(treino, [
      _p(1),
      _p(1, te: 3, execucao: 99),
    ]);
    expect(atual.exercicios.first.seriesFeitas, 1);
    expect(atual.exercicios.last.seriesFeitas, 0);
    expect(checkinPendentesDaExecucao([_p(1), _p(2, execucao: 9)], 1), 1);
    expect(checkinPendentesDaExecucao([_p(1)], null), 0);
  });

  test('conta exercícios que faltam', () {
    expect(
      checkinExerciciosFaltando([
        _ee(concluido: true),
        _ee(id: 11, feitas: 1),
        _ee(id: 12),
      ]),
      2,
    );
    expect(checkinExerciciosFaltando([_ee(concluido: true)]), 0);
  });

  test('evolução de carga antiga vira performance', () {
    final concluida = ExecucaoTreino(
      id: 1,
      treinoId: 5,
      treinoNome: 'Treino A',
      status: 'CONCLUIDO',
      exercicios: const [],
      evolucoesCarga: const [
        EvolucaoCarga(
          exercicioId: 3,
          exercicioNome: 'Supino',
          cargaAnteriorKg: 20,
          cargaAtualKg: 25,
          diferencaKg: 5,
          mensagem: 'Boa',
        ),
      ],
    );
    final evolucoes = checkinEvolucoesParaCelebrar(concluida);
    expect(evolucoes.single.tipo, 'CARGA');
    expect(evolucoes.single.valorAtual, 25);
    expect(evolucoes.single.unidade, 'kg');
  });
}
