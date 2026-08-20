import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_day_lane.dart';

Agendamento _ag({
  required int id,
  required DateTime inicio,
  DateTime? fim,
  String status = 'AGENDADO',
}) {
  return Agendamento(
    id: id,
    alunoId: 1,
    alunoNome: 'Beatriz',
    inicio: inicio,
    fim: fim ?? inicio.add(const Duration(hours: 1)),
    status: status,
  );
}

void main() {
    test('lane esconde cancelado e insere lacuna', () {
    final items = agendaBuildDayLane([
      _ag(id: 1, inicio: DateTime(2026, 8, 19, 8, 30)),
      _ag(id: 2, inicio: DateTime(2026, 8, 19, 9, 30), status: 'CANCELADO'),
      _ag(id: 3, inicio: DateTime(2026, 8, 19, 11)),
    ]);
    expect(items.length, 3);
    expect(items[0], isA<AgendaLaneEvent>());
    expect(items[1], isA<AgendaLaneGap>());
    final gap = items[1] as AgendaLaneGap;
    expect(gap.duration, const Duration(minutes: 90));
    expect(items[2], isA<AgendaLaneEvent>());
    expect(agendaCancelledCount([
      _ag(id: 1, inicio: DateTime(2026, 8, 19, 8, 30)),
      _ag(id: 2, inicio: DateTime(2026, 8, 19, 9, 30), status: 'CANCELADO'),
    ]), 1);
  });

  test('label da lacuna', () {
    expect(agendaGapLabel(const Duration(minutes: 30)), '30 min livres');
    expect(agendaGapLabel(const Duration(hours: 1)), '1 hora livre');
    expect(agendaGapLabel(const Duration(hours: 2, minutes: 15)), '2h 15min livres');
  });
}
