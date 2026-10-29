import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/utils/semana_prevista.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';

RotinaItem _treino(int id, String nome, int dia) =>
    RotinaItem(id: id, tipo: RotinaItemTipo.treino, treinoId: id, nome: nome, diaSemana: dia);

ExecucaoTreino _feito(int treinoId, DateTime quando) => ExecucaoTreino(
  id: treinoId * 10,
  treinoId: treinoId,
  treinoNome: 'T$treinoId',
  status: 'CONCLUIDO',
  iniciadoEm: quando.toIso8601String(),
  concluidoEm: quando.toIso8601String(),
  exercicios: const [],
);

/// ABC em 5 dias: Seg A, Ter B, Qua C, Qui e Sex seguem a sequência.
final _abc5 = RotinaFila(
  itens: [_treino(1, 'A', 1), _treino(2, 'B', 2), _treino(3, 'C', 3)],
  diasAviso: const {6, 7},
);

void main() {
  test('sem histórico, a semana começa pelo A', () {
    final segunda = DateTime(2026, 10, 26, 8);
    final previstos = nomesPrevistosDaSemana(rotina: _abc5, historico: const [], hoje: segunda);
    expect(previstos, {1: 'A', 2: 'B', 3: 'C', 4: 'A', 5: 'B'});
  });

  test('depois de fazer o C na quarta, quinta prevê A e sexta B', () {
    final quarta = DateTime(2026, 10, 28, 19);
    final previstos = nomesPrevistosDaSemana(
      rotina: _abc5,
      historico: [_feito(3, quarta)],
      hoje: quarta,
    );
    expect(previstos, {4: 'A', 5: 'B'});
  });

  test('faltar não pula: último feito foi o A, quinta prevê B', () {
    final segunda = DateTime(2026, 10, 26, 19);
    final quinta = DateTime(2026, 10, 29, 8);
    final previstos = nomesPrevistosDaSemana(
      rotina: _abc5,
      historico: [_feito(1, segunda)],
      hoje: quinta,
    );
    expect(previstos, {4: 'B', 5: 'C'});
  });

  test('fila sem treino não prevê nada', () {
    expect(
      nomesPrevistosDaSemana(rotina: RotinaFila.vazia, historico: const [], hoje: DateTime(2026, 10, 26)),
      isEmpty,
    );
  });
}
