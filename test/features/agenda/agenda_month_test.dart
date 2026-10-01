import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/agenda/data/agenda_repository.dart';
import 'package:focux_app/features/agenda/utils/agenda_month.dart';

Agendamento _ag(int id, DateTime inicio, {String status = 'AGENDADO'}) =>
    Agendamento(
      id: id,
      alunoId: 1,
      alunoNome: 'Aluno Exemplo',
      inicio: inicio,
      fim: inicio.add(const Duration(hours: 1)),
      status: status,
    );

void main() {
  test('grade começa na segunda e tem 6 semanas', () {
    final grid = agendaMonthGrid(DateTime(2026, 10));
    expect(grid, hasLength(42));
    expect(grid.first, DateTime(2026, 9, 28));
    expect(grid.last, DateTime(2026, 11, 8));
    expect(agendaMonthGrid(DateTime(2026, 6)).first, DateTime(2026, 6, 1));
  });

  test('grade atravessa horário de verão sem pular dia', () {
    final grid = agendaMonthGrid(DateTime(2026, 11));
    for (var i = 1; i < grid.length; i++) {
      expect(grid[i].difference(grid[i - 1]).inHours, inInclusiveRange(23, 25));
      expect(grid[i].hour, 0);
    }
  });

  test('troca de mês vira o ano', () {
    expect(agendaShiftMonth(DateTime(2026, 12), 1), DateTime(2027, 1));
    expect(agendaShiftMonth(DateTime(2026, 1), -1), DateTime(2025, 12));
  });

  test('rótulo omite o ano corrente', () {
    final now = DateTime(2026, 10, 1);
    expect(agendaMonthLabel(DateTime(2026, 10), now: now), 'Outubro');
    expect(agendaMonthLabel(DateTime(2027, 1), now: now), 'Janeiro 2027');
  });

  test('dia inicial: hoje no mês atual, dia 1 nos outros', () {
    final now = DateTime(2026, 10, 15, 9);
    expect(
      agendaDefaultSelectedDay(DateTime(2026, 10), now: now),
      DateTime(2026, 10, 15),
    );
    expect(
      agendaDefaultSelectedDay(DateTime(2026, 11), now: now),
      DateTime(2026, 11, 1),
    );
  });

  test('contagem por dia ignora cancelados', () {
    final items = [
      _ag(1, DateTime(2026, 10, 2, 8)),
      _ag(2, DateTime(2026, 10, 2, 10)),
      _ag(3, DateTime(2026, 10, 2, 12), status: 'CANCELADO'),
      _ag(4, DateTime(2026, 10, 5, 7)),
    ];
    expect(agendaVisibleCountByDay(items), {'2026-10-02': 2, '2026-10-05': 1});
    expect(agendaEventsOn(items, DateTime(2026, 10, 2)).map((a) => a.id), [
      1,
      2,
      3,
    ]);
  });

  test('a11y do dia fala data, hoje e quantidade', () {
    expect(
      agendaMonthDayA11y(day: DateTime(2026, 10, 1), count: 2, isToday: true),
      'Qui 1 de outubro, hoje, 2 atendimentos',
    );
  });
}
