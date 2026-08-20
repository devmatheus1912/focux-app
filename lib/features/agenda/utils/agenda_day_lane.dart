import '../data/agenda_repository.dart';
import 'agenda_status.dart';

Map<int, List<Agendamento>> agendaEventsByWeekday(
  List<Agendamento> items,
  DateTime weekStart,
) {
  final map = <int, List<Agendamento>>{
    for (var i = 0; i < 7; i++) i: <Agendamento>[],
  };
  for (final ag in items) {
    final diff = ag.inicio.difference(weekStart).inDays;
    if (diff >= 0 && diff < 7) {
      map[ag.inicio.weekday - 1]?.add(ag);
    }
  }
  return map;
}

sealed class AgendaLaneItem {
  const AgendaLaneItem();
}

class AgendaLaneEvent extends AgendaLaneItem {
  const AgendaLaneEvent({required this.agendamento, required this.next});

  final Agendamento agendamento;
  final bool next;
}

class AgendaLaneGap extends AgendaLaneItem {
  const AgendaLaneGap({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  Duration get duration => to.difference(from);
}

List<Agendamento> agendaVisibleEvents(List<Agendamento> events) {
  final visible =
      events.where((e) => e.status != 'CANCELADO').toList()
        ..sort((a, b) => a.inicio.compareTo(b.inicio));
  return visible;
}

List<AgendaLaneItem> agendaBuildDayLane(
  List<Agendamento> events, {
  DateTime? now,
  int minGapMinutes = 20,
}) {
  final visible = agendaVisibleEvents(events);
  final next = agendaNextOpen(visible, now: now);
  final items = <AgendaLaneItem>[];
  for (var i = 0; i < visible.length; i++) {
    if (i > 0) {
      final prevEnd = visible[i - 1].fim;
      final start = visible[i].inicio;
      if (start.isAfter(prevEnd) &&
          start.difference(prevEnd).inMinutes >= minGapMinutes) {
        items.add(AgendaLaneGap(from: prevEnd, to: start));
      }
    }
    items.add(
      AgendaLaneEvent(
        agendamento: visible[i],
        next: next?.id == visible[i].id,
      ),
    );
  }
  return items;
}

String agendaGapLabel(Duration duration) {
  final m = duration.inMinutes;
  if (m < 60) return '$m min livres';
  final h = m ~/ 60;
  final rest = m % 60;
  if (rest == 0) return h == 1 ? '1 hora livre' : '$h horas livres';
  return '${h}h ${rest}min livres';
}

int agendaCancelledCount(List<Agendamento> events) =>
    events.where((e) => e.status == 'CANCELADO').length;
