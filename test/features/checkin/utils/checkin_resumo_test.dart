import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/data/checkin_repository.dart';
import 'package:focux_app/features/checkin/utils/checkin_resumo.dart';

ExecucaoTreino _treino({
  List<ExecucaoExercicio> exercicios = const [],
  List<EvolucaoPerformance> performance = const [],
  String? iniciadoEm = '2026-10-01T18:00:00',
  String? concluidoEm = '2026-10-01T18:52:00',
}) => ExecucaoTreino(
  id: 9,
  treinoId: 2,
  treinoNome: 'Costas e Bíceps',
  status: 'CONCLUIDO',
  iniciadoEm: iniciadoEm,
  concluidoEm: concluidoEm,
  exercicios: exercicios,
  evolucoesPerformance: performance,
);

SessaoEvolucaoDto _evo({
  double? volume = 2400,
  double? anterior = 2000,
  String sinal = 'MELHOROU',
  String? destaque,
  double? destaqueKg,
}) => SessaoEvolucaoDto(
  volumeKg: volume,
  volumeAnteriorKg: anterior,
  seriesFeitas: 24,
  seriesPlanejadas: 26,
  recordes: 0,
  sinal: sinal,
  sinalLabel: '',
  destaqueExercicio: destaque,
  destaqueDeltaKg: destaqueKg,
);

void main() {
  test('números da sessão vêm da evolução do servidor', () {
    final r = buildCheckinResumo(concluida: _treino(), evolucao: _evo());
    expect(r.treinoNome, 'Costas e Bíceps');
    expect(r.duracao, const Duration(minutes: 52));
    expect(r.seriesFeitas, 24);
    expect(r.seriesPlanejadas, 26);
    expect(r.volumeKg, 2400);
  });

  test('comparação em % contra a última sessão', () {
    expect(
      buildCheckinResumo(concluida: _treino(), evolucao: _evo()).comparacao,
      const CheckinResumoComparacao.mais(20),
    );
    expect(
      buildCheckinResumo(
        concluida: _treino(),
        evolucao: _evo(volume: 1800, sinal: 'CAIU'),
      ).comparacao,
      const CheckinResumoComparacao.menos(10),
    );
    expect(
      buildCheckinResumo(
        concluida: _treino(),
        evolucao: _evo(volume: 2010, sinal: 'MANTEVE'),
      ).comparacao,
      const CheckinResumoComparacao.igual(),
    );
    expect(
      buildCheckinResumo(
        concluida: _treino(),
        evolucao: _evo(anterior: null, sinal: 'PRIMEIRA'),
      ).comparacao,
      const CheckinResumoComparacao.primeira(),
    );
  });

  test('sem evolução nem volume não inventa comparação', () {
    final r = buildCheckinResumo(concluida: _treino(), evolucao: null);
    expect(r.comparacao, isNull);
    expect(r.volumeKg, isNull);
  });

  test('recordes reais primeiro; destaque só quando não há recorde', () {
    const pr = EvolucaoPerformance(
      tipo: 'CARGA',
      exercicioId: 1,
      exercicioNome: 'Remada',
      valorAnterior: 40,
      valorAtual: 45,
      diferenca: 5,
      unidade: 'kg',
      mensagem: '',
    );
    final comPr = buildCheckinResumo(
      concluida: _treino(performance: [pr]),
      evolucao: _evo(destaque: 'Rosca', destaqueKg: 2),
    );
    expect(comPr.recordes.single.exercicioNome, 'Remada');
    expect(comPr.destaque, isNull);

    final soDestaque = buildCheckinResumo(
      concluida: _treino(),
      evolucao: _evo(destaque: 'Rosca', destaqueKg: 2),
    );
    expect(soDestaque.recordes, isEmpty);
    expect(soDestaque.destaque, (exercicio: 'Rosca', deltaKg: 2.0));
  });

  test('sem resposta do concluir usa o nome do treino local', () {
    final r = buildCheckinResumo(
      concluida: null,
      evolucao: null,
      treinoNomeLocal: 'Pernas',
    );
    expect(r.treinoNome, 'Pernas');
    expect(r.duracao, isNull);
    expect(r.temNumeros, isFalse);
  });

  test('duração implausível some', () {
    final r = buildCheckinResumo(
      concluida: _treino(concluidoEm: '2026-10-03T18:00:00'),
      evolucao: _evo(),
    );
    expect(r.duracao, isNull);
  });
}
