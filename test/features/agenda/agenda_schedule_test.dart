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

  test('card mostra o aluno; título vira nota', () {
    expect(
      agendaEventTitle(alunoNome: 'Bruno', titulo: 'oi'),
      'Bruno',
    );
    expect(agendaEventNote('oi'), 'oi');
    expect(agendaEventNote('  '), isNull);
    expect(agendaEventTitle(alunoNome: '  ', titulo: 'Avaliação'), 'Avaliação');
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
    expect(
      agendaEmptyDaySubtitle(
        weekdayLabel: 'Qui',
        date: DateTime(2026, 8, 20),
      ),
      'Qui, 20 ago · encaixe avaliação, retorno ou sessão.',
    );
  });
}
