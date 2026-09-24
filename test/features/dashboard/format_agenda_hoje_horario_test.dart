import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/dashboard/utils/format_agenda_hoje_horario.dart';

void main() {
  final now = DateTime(2026, 9, 23, 18, 0);

  test('hoje → só hora', () {
    expect(
      formatAgendaHojeHorario('2026-09-23T12:00', now: now),
      '12:00',
    );
  });

  test('outro dia → dia + mês + hora', () {
    expect(
      formatAgendaHojeHorario('2026-09-24T09:30:00', now: now),
      '24 set · 09:30',
    );
  });

  test('já humano passa', () {
    expect(formatAgendaHojeHorario('12:00', now: now), '12:00');
  });
}
