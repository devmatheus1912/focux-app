import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/checkin/models/checkin_execucao_models.dart';
import 'package:focux_app/features/checkin/utils/rotina_decisao.dart';
import 'package:focux_app/features/treinos/models/rotina_fila.dart';

void main() {
  final hoje = DateTime(2026, 10, 26);
  final ontem = DateTime(2026, 10, 25);

  test('três treinos, nada feito: o primeiro é agora e cita o seguinte', () {
    final d = decisaoDaRotina(
      itens: [t(1, 'A'), t(2, 'B'), t(3, 'C')],
      diasAviso: const {},
      treinos: [ficha(1, 'A'), ficha(2, 'B'), ficha(3, 'C')],
      historico: const [],
      agora: hoje,
    );
    expect(d!.momento, RotinaMomento.agora);
    expect(d.foco.treinoNome, 'A');
    expect(d.ordem, 1);
    expect(d.ordemTotal, 3);
    expect(d.depoisNome, 'B');
  });

  test('faltou um dia: o card é o treino seguinte, não o mesmo', () {
    final d = decisaoDaRotina(
      itens: [t(1, 'A'), t(2, 'B'), t(3, 'C')],
      diasAviso: const {},
      treinos: [ficha(1, 'A'), ficha(2, 'B'), ficha(3, 'C')],
      historico: [feito(1, 'A', ontem)],
      agora: hoje,
    );
    expect(d!.momento, RotinaMomento.agora);
    expect(d.foco.treinoNome, 'B');
  });

  test('dois no mesmo dia: terminou um e o próximo continua disponível', () {
    final d = decisaoDaRotina(
      itens: [t(1, 'A'), t(2, 'B')],
      diasAviso: const {},
      treinos: [ficha(1, 'A'), ficha(2, 'B')],
      historico: [feito(1, 'A', hoje)],
      agora: hoje,
    );
    expect(d!.momento, RotinaMomento.pronto);
    expect(d.proximoEhDescanso, isFalse);
    expect(d.depoisNome, 'B');
  });

  test('descanso depois do segundo não segura o dia seguinte', () {
    final fila = [t(1, 'A'), t(2, 'B'), d(9), t(3, 'C')];
    final treinos = [ficha(1, 'A'), ficha(2, 'B'), ficha(3, 'C')];
    final aoTerminar = decisaoDaRotina(
      itens: fila,
      diasAviso: const {},
      treinos: treinos,
      historico: [feito(2, 'B', hoje)],
      agora: hoje,
    );
    expect(aoTerminar!.proximoEhDescanso, isTrue);
    expect(aoTerminar.depoisNome, 'C');

    final diaSeguinte = decisaoDaRotina(
      itens: fila,
      diasAviso: const {},
      treinos: treinos,
      historico: [feito(2, 'B', ontem)],
      agora: hoje,
    );
    expect(diaSeguinte!.momento, RotinaMomento.agora);
    expect(diaSeguinte.foco.treinoNome, 'C');
  });

  test('domingo marcado, sem treino hoje, avisa e o treino continua o próximo', () {
    final d = decisaoDaRotina(
      itens: [t(1, 'A'), t(2, 'B')],
      diasAviso: const {7},
      treinos: [ficha(1, 'A'), ficha(2, 'B')],
      historico: [feito(1, 'A', DateTime(2026, 10, 24))],
      agora: DateTime(2026, 10, 25),
    );
    expect(d!.momento, RotinaMomento.descansoDia);
    expect(d.foco.treinoNome, 'B');
  });

  test('arrastar o terceiro para o começo muda o treino de agora', () {
    final d = decisaoDaRotina(
      itens: [t(3, 'C'), t(1, 'A'), t(2, 'B')],
      diasAviso: const {},
      treinos: [ficha(1, 'A'), ficha(2, 'B'), ficha(3, 'C')],
      historico: const [],
      agora: hoje,
    );
    expect(d!.foco.treinoNome, 'C');
    expect(d.depoisNome, 'A');
  });
}

RotinaItem t(int id, String nome) => RotinaItem(
  id: id,
  tipo: RotinaItemTipo.treino,
  treinoId: id,
  nome: nome,
);

RotinaItem d(int id) => RotinaItem(id: id, tipo: RotinaItemTipo.descanso);

ExecucaoTreino ficha(int id, String nome) => ExecucaoTreino(
  treinoId: id,
  treinoNome: nome,
  status: 'DISPONIVEL',
  exercicios: const [],
  exerciciosCount: 4,
);

ExecucaoTreino feito(int id, String nome, DateTime quando) => ExecucaoTreino(
  id: id,
  treinoId: id,
  treinoNome: nome,
  status: 'CONCLUIDO',
  iniciadoEm: quando.subtract(const Duration(hours: 1)).toIso8601String(),
  concluidoEm: quando.toIso8601String(),
  exercicios: const [],
);
