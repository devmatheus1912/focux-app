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

  test('lembrete de whatsapp usa primeiro nome e horário', () {
    expect(
      agendaWhatsappReminder(
        alunoNome: 'Beatriz Carvalho',
        inicio: DateTime(2026, 8, 19, 8, 30),
      ),
      'Oi Beatriz, confirmando nosso horário às 08:30.',
    );
  });
}
