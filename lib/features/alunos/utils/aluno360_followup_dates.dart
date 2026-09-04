class AlunoFollowUpDateOption {
  const AlunoFollowUpDateOption({
    required this.days,
    required this.date,
    required this.label,
    required this.subtitle,
  });

  final int days;
  final DateTime date;
  final String label;
  final String subtitle;
}

const alunoFollowUpDateHorizons = [0, 1, 3, 7, 14, 30];

String alunoFollowUpDateLabel(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String alunoFollowUpHorizonLabel(int days) {
  switch (days) {
    case 0:
      return 'Hoje';
    case 1:
      return 'Amanhã';
    default:
      return 'Em $days dias';
  }
}

List<AlunoFollowUpDateOption> alunoFollowUpDateOptions(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  return [
    for (final days in alunoFollowUpDateHorizons)
      AlunoFollowUpDateOption(
        days: days,
        date: today.add(Duration(days: days)),
        label: alunoFollowUpHorizonLabel(days),
        subtitle: alunoFollowUpDateLabel(today.add(Duration(days: days))),
      ),
  ];
}

DateTime? alunoFollowUpDateSelected({
  required List<AlunoFollowUpDateOption> options,
  required DateTime? current,
}) {
  if (current == null) return null;
  final day = DateTime(current.year, current.month, current.day);
  for (final option in options) {
    if (option.date.year == day.year &&
        option.date.month == day.month &&
        option.date.day == day.day) {
      return option.date;
    }
  }
  return null;
}
