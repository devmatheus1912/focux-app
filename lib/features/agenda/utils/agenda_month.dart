import '../data/agenda_repository.dart';
import 'agenda_day_lane.dart';
import 'agenda_schedule.dart';

const agendaMonthGridDays = 42;

const agendaMonthNames = [
  '',
  'Janeiro',
  'Fevereiro',
  'Março',
  'Abril',
  'Maio',
  'Junho',
  'Julho',
  'Agosto',
  'Setembro',
  'Outubro',
  'Novembro',
  'Dezembro',
];

const agendaWeekdayInitials = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

DateTime agendaMonthOf(DateTime d) => DateTime(d.year, d.month);

DateTime agendaShiftMonth(DateTime month, int delta) =>
    DateTime(month.year, month.month + delta);

String agendaMonthLabel(DateTime month) =>
    '${agendaMonthNames[month.month]} ${month.year}';

/// Semanas da grade que têm algum dia do mês (4 a 6).
int agendaMonthWeeks(DateTime month) {
  final offset = DateTime(month.year, month.month).weekday - 1;
  final dias = DateTime(month.year, month.month + 1, 0).day;
  return ((offset + dias) / 7).ceil();
}

/// Segunda-feira da semana que contém o dia 1; a grade cobre 6 semanas.
DateTime agendaMonthGridStart(DateTime month) {
  final first = DateTime(month.year, month.month);
  return DateTime(month.year, month.month, 2 - first.weekday);
}

List<DateTime> agendaMonthGrid(DateTime month) {
  final start = agendaMonthGridStart(month);
  return [
    for (var i = 0; i < agendaMonthGridDays; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}

/// Mês corrente abre em hoje; os outros, no dia 1.
DateTime agendaDefaultSelectedDay(DateTime month, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (month.year == n.year && month.month == n.month) {
    return DateTime(n.year, n.month, n.day);
  }
  return DateTime(month.year, month.month);
}

List<Agendamento> agendaEventsOn(List<Agendamento> items, DateTime day) =>
    items.where((a) => agendaSameDay(a.inicio, day)).toList()
      ..sort((a, b) => a.inicio.compareTo(b.inicio));

/// Atendimentos não cancelados por dia (chave ISO), em ordem de horário.
Map<String, List<Agendamento>> agendaVisibleByDay(List<Agendamento> items) {
  final byDay = <String, List<Agendamento>>{};
  for (final ag in agendaVisibleEvents(items)) {
    (byDay[agendaIsoDate(ag.inicio)] ??= []).add(ag);
  }
  return byDay;
}

/// Chip da célula: "9h Ana" / "9h30 Ana".
String agendaChipLabel(Agendamento a) {
  final h = a.inicio.hour;
  final m = a.inicio.minute;
  final hora = m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';
  final nome = a.alunoNome.trim().split(RegExp(r'\s+')).first;
  return nome.isEmpty ? hora : '$hora $nome';
}

String agendaMonthDayA11y({
  required DateTime day,
  required int count,
  required bool isToday,
}) {
  return [
    '${agendaWeekdayShort(day.weekday)} ${day.day} de ${agendaMonthNames[day.month].toLowerCase()}',
    if (isToday) 'hoje',
    if (count > 0) '$count atendimento${count == 1 ? '' : 's'}',
  ].join(', ');
}
