import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_display.dart';
import 'package:focux_app/features/agenda/utils/agenda_status.dart';

Agendamento _ag({
  required DateTime inicio,
  DateTime? fim,
  String status = 'AGENDADO',
  String nome = 'Beatriz',
}) {
  return Agendamento(
    id: 1,
    alunoId: 9,
    alunoNome: nome,
    inicio: inicio,
    fim: fim ?? inicio.add(const Duration(hours: 1)),
    status: status,
  );
}

void main() {
  test('label e acionável', () {
    expect(agendaStatusLabel('AGENDADO'), 'Agendado');
    expect(agendaStatusLabel('CONFIRMADO'), 'Confirmado');
    expect(agendaStatusIsActionable('AGENDADO'), isTrue);
    expect(agendaStatusIsActionable('CONCLUIDO'), isFalse);
    expect(agendaStatusNeedsConfirm('AGENDADO'), isTrue);
    expect(agendaStatusNeedsConfirm('CONFIRMADO'), isFalse);
  });

  test('agenda aluno count e chips', () {
    expect(agendaAlunoCountLabel(0), 'Nenhum compromisso');
    expect(agendaAlunoCountLabel(1), '1 compromisso');
    expect(agendaAlunoCountLabel(3), '3 compromissos');
    expect(agendaAlunoChipLabel(AgendaAlunoChip.confirmar), 'A confirmar');
    expect(agendaAlunoChipStatus(AgendaAlunoChip.confirmar), 'AGENDADO');
    expect(agendaAlunoChipStatus(AgendaAlunoChip.todos), isNull);
    expect(agendaAlunoDefaultTitle(null), 'Sessão de treino');
    expect(
      agendaAlunoWhenLabel(
        DateTime(2026, 9, 9, 7, 0),
        DateTime(2026, 9, 9, 8, 0),
      ),
      '09/09 07:00 – 08:00',
    );
  });

  test('próximo aberto ignora passado e cancelado', () {
    final now = DateTime(2026, 8, 19, 10);
    final next = agendaNextOpen(
      [
        _ag(inicio: DateTime(2026, 8, 19, 8), status: 'AGENDADO'),
        _ag(inicio: DateTime(2026, 8, 19, 11), status: 'CANCELADO'),
        _ag(inicio: DateTime(2026, 8, 19, 12), status: 'CONFIRMADO'),
      ],
      now: now,
    );
    expect(next?.inicio, DateTime(2026, 8, 19, 12));
  });

  test('sessão due quando já começou ou está a 15 min', () {
    final ag = _ag(inicio: DateTime(2026, 8, 19, 8, 30));
    expect(
      agendaSessionIsDue(ag, now: DateTime(2026, 8, 19, 8, 20)),
      isTrue,
    );
    expect(
      agendaSessionIsDue(ag, now: DateTime(2026, 8, 19, 7)),
      isFalse,
    );
  });
}
