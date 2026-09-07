import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/utils/agenda_schedule.dart';

void main() {
  test('slot no mesmo dia arredonda para o próximo 30 min', () {
    expect(
      agendaDefaultSlot(
        DateTime(2026, 8, 19),
        now: DateTime(2026, 8, 19, 21, 10),
      ),
      DateTime(2026, 8, 19, 21, 30),
    );
    expect(
      agendaDefaultSlot(
        DateTime(2026, 8, 19),
        now: DateTime(2026, 8, 19, 21, 30),
      ),
      DateTime(2026, 8, 19, 22, 0),
    );
  });

  test('outro dia abre em 08:30', () {
    expect(
      agendaDefaultSlot(
        DateTime(2026, 8, 20),
        now: DateTime(2026, 8, 19, 21, 10),
      ),
      DateTime(2026, 8, 20, 8, 30),
    );
  });

  test('card mostra o aluno; título vira nota quando útil', () {
    expect(
      agendaEventTitle(alunoNome: 'Bruno', titulo: 'oi'),
      'Bruno',
    );
    expect(agendaEventSessionNote('oi'), isNull);
    expect(agendaEventSessionNote('Avaliação'), 'Avaliação');
    expect(agendaEventNote('  '), isNull);
    expect(agendaEventTitle(alunoNome: '  ', titulo: 'Avaliação'), 'Avaliação');
  });

  test('subtítulo do sheet resume horário e status', () {
    expect(
      agendaEventSheetSubtitle(
        inicio: DateTime(2026, 8, 19, 8, 30),
        fim: DateTime(2026, 8, 19, 9, 30),
        statusLabel: 'Agendado',
      ),
      '08:30–09:30 · Agendado',
    );
  });

  test('iso date e segunda da semana', () {
    expect(agendaIsoDate(DateTime(2026, 8, 19)), '2026-08-19');
    expect(agendaWeekStart(DateTime(2026, 8, 19)), DateTime(2026, 8, 17));
    expect(agendaHm(DateTime(2026, 8, 19, 8, 30)), '08:30');
  });

  test('heading omite zero atendimentos', () {
    expect(
      agendaDayHeading(
        weekdayLabel: 'Qui',
        date: DateTime(2026, 8, 20),
        visibleCount: 0,
      ),
      'Qui · 20 ago',
    );
    expect(
      agendaDayHeading(
        weekdayLabel: 'Qui',
        date: DateTime(2026, 8, 20),
        visibleCount: 1,
      ),
      'Qui · 20 ago · 1 atendimento',
    );
    expect(agendaEmptyDayHint(), 'Encaixe avaliação, retorno ou sessão.');
  });

  test('copy de agendar e concluir fica fora da UI', () {
    expect(agendaNovoTileLabel(), 'Agendar atendimento');
    expect(agendaNovoConfirmTitle(), 'Agendar este horário?');
    expect(agendaNovoDiscardTitle(), 'Descartar agendamento?');
    expect(agendaNovoDiscardMessage(), 'O que você preencheu não será salvo.');
    expect(
      agendaNovoConfirmMessage(
        alunoNome: 'Bruno',
        inicio: DateTime(2026, 8, 19, 8, 30),
        fim: DateTime(2026, 8, 19, 9, 30),
      ),
      'Confirma Bruno em 08:30–09:30.',
    );
    expect(agendaEventPrimaryLabel(completePrimary: true), 'Marcar concluído');
    expect(agendaEventPrimaryLabel(completePrimary: false), 'Abrir aluno');
    expect(agendaTituloMax, 120);
  });
}
