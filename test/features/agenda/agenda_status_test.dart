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

Agendamento _agAtendimento(DateTime inicio, String status, String atendimento) {
  return Agendamento(
    id: 2,
    alunoId: 9,
    alunoNome: 'Beatriz',
    inicio: inicio,
    fim: inicio.add(const Duration(hours: 1)),
    status: status,
    statusAtendimento: atendimento,
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
  });

  group('agenda aluno', () {
    final now = DateTime(2026, 11, 19, 10);

    test('rótulo do dia tem dia da semana, Hoje e Amanhã', () {
      expect(
        agendaAlunoDiaLabel(
          DateTime(2026, 11, 20, 8, 30),
          DateTime(2026, 11, 20, 9, 30),
          now: DateTime(2026, 11, 10),
        ),
        'Sex, 20 nov · 08:30–09:30',
      );
      expect(
        agendaAlunoDiaLabel(
          DateTime(2026, 11, 19, 18),
          DateTime(2026, 11, 19, 19),
          now: now,
        ),
        'Hoje · 18:00–19:00',
      );
      expect(
        agendaAlunoDiaLabel(
          DateTime(2026, 11, 20, 7),
          DateTime(2026, 11, 20, 8),
          now: now,
        ),
        'Amanhã · 07:00–08:00',
      );
    });

    test('separa próximas (crescente) de anteriores (decrescente)', () {
      final items = [
        _ag(inicio: DateTime(2026, 9, 24, 12)),
        _ag(inicio: DateTime(2026, 11, 25, 8)),
        _ag(inicio: DateTime(2026, 11, 20, 8, 30)),
        _ag(inicio: DateTime(2026, 10, 1, 12)),
        _ag(inicio: DateTime(2026, 11, 19, 9, 30)),
      ];
      expect(agendaAlunoProximas(items, now: now).map((a) => a.inicio), [
        DateTime(2026, 11, 19, 9, 30),
        DateTime(2026, 11, 20, 8, 30),
        DateTime(2026, 11, 25, 8),
      ]);
      expect(agendaAlunoAnteriores(items, now: now).map((a) => a.inicio), [
        DateTime(2026, 10, 1, 12),
        DateTime(2026, 9, 24, 12),
      ]);
    });

    test('confirmar só em sessão futura ainda agendada', () {
      expect(
        agendaAlunoPodeConfirmar(
          _ag(inicio: DateTime(2026, 11, 20, 8)),
          now: now,
        ),
        isTrue,
      );
      expect(
        agendaAlunoPodeConfirmar(
          _ag(inicio: DateTime(2026, 9, 24, 12)),
          now: now,
        ),
        isFalse,
      );
      expect(
        agendaAlunoPodeConfirmar(
          _ag(inicio: DateTime(2026, 11, 20, 8), status: 'CONFIRMADO'),
          now: now,
        ),
        isFalse,
      );
    });

    test('sessão passada mostra comparecimento, nunca Confirmar', () {
      final passada = DateTime(2026, 9, 24, 12);
      expect(
        agendaAlunoStatusLabel(
          _agAtendimento(passada, 'AGENDADO', 'PRESENTE'),
          now: now,
        ),
        'Compareceu',
      );
      expect(
        agendaAlunoStatusLabel(
          _agAtendimento(passada, 'CONFIRMADO', 'FALTA'),
          now: now,
        ),
        'Faltou',
      );
      expect(
        agendaAlunoStatusLabel(_ag(inicio: passada), now: now),
        'Agendado',
      );
      expect(
        agendaAlunoStatusLabel(
          _ag(inicio: DateTime(2026, 11, 20, 8), status: 'CONFIRMADO'),
          now: now,
        ),
        'Confirmado',
      );
    });
  });

  test('próximo aberto ignora passado e cancelado', () {
    final now = DateTime(2026, 8, 19, 10);
    final next = agendaNextOpen([
      _ag(inicio: DateTime(2026, 8, 19, 8), status: 'AGENDADO'),
      _ag(inicio: DateTime(2026, 8, 19, 11), status: 'CANCELADO'),
      _ag(inicio: DateTime(2026, 8, 19, 12), status: 'CONFIRMADO'),
    ], now: now);
    expect(next?.inicio, DateTime(2026, 8, 19, 12));
  });

  test('sessão due quando já começou ou está a 15 min', () {
    final ag = _ag(inicio: DateTime(2026, 8, 19, 8, 30));
    expect(agendaSessionIsDue(ag, now: DateTime(2026, 8, 19, 8, 20)), isTrue);
    expect(agendaSessionIsDue(ag, now: DateTime(2026, 8, 19, 7)), isFalse);
  });
}
