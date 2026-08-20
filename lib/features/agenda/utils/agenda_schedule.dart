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

String agendaIsoDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

DateTime agendaWeekStart(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

String agendaHm(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String agendaWhatsappReminder({
  required String alunoNome,
  required DateTime inicio,
}) {
  final parts = alunoNome.trim().split(RegExp(r'\s+'));
  final first = parts.isEmpty || parts.first.isEmpty ? 'oi' : parts.first;
  return 'Oi $first, confirmando nosso horário às ${agendaHm(inicio)}.';
}
