DateTime agendaDefaultSlot(DateTime day, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final sameDay = day.year == n.year && day.month == n.month && day.day == n.day;
  if (!sameDay) {
    return DateTime(day.year, day.month, day.day, 8, 30);
  }
  var hour = n.hour;
  var minute = 30;
  if (n.minute >= 30) {
    hour += 1;
    minute = 0;
  }
  if (hour < 6) {
    return DateTime(n.year, n.month, n.day, 8, 30);
  }
  if (hour > 22 || (hour == 22 && minute > 0)) {
    return DateTime(n.year, n.month, n.day, 22, 0);
  }
  return DateTime(n.year, n.month, n.day, hour, minute);
}

bool agendaSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String agendaWeekdayShort(int weekday) =>
    const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'][weekday - 1];

String agendaEventTitle({required String alunoNome, String? titulo}) {
  final name = alunoNome.trim();
  return name.isEmpty ? (titulo?.trim().isNotEmpty == true ? titulo!.trim() : 'Atendimento') : name;
}

String? agendaEventNote(String? titulo) {
  final t = titulo?.trim();
  if (t == null || t.isEmpty) return null;
  return t;
}
