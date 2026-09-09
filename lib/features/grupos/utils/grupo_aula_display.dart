String grupoAulaWhenLabel(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}

String grupoAulaDateLabel(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month';
}

bool grupoAulaSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime grupoAulaDay(DateTime d) => DateTime(d.year, d.month, d.day);

const grupoAulaDateHorizons = [0, 1, 3, 7, 14, 30];

String grupoAulaDateOptionLabel(DateTime date, DateTime today) {
  final d = grupoAulaDay(date);
  final t = grupoAulaDay(today);
  final diff = d.difference(t).inDays;
  if (diff == 0) return 'Hoje';
  if (diff == 1) return 'Amanhã';
  if (diff == -1) return 'Ontem';
  if (diff > 1) return 'Em $diff dias';
  return 'Há ${-diff} dias';
}

List<DateTime> grupoAulaDateOptions({
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? initial,
  DateTime? now,
}) {
  final first = grupoAulaDay(firstDate);
  final last = grupoAulaDay(lastDate);
  final span = last.difference(first).inDays;
  if (span <= 2) {
    final out = <DateTime>[];
    for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) {
      out.add(d);
    }
    return out;
  }
  final today = grupoAulaDay(now ?? DateTime.now());
  final out = <DateTime>[];
  for (final h in grupoAulaDateHorizons) {
    final d = today.add(Duration(days: h));
    if (d.isBefore(first) || d.isAfter(last)) continue;
    if (!out.any((x) => grupoAulaSameDay(x, d))) out.add(d);
  }
  if (initial != null) {
    final i = grupoAulaDay(initial);
    if (!i.isBefore(first) &&
        !i.isAfter(last) &&
        !out.any((x) => grupoAulaSameDay(x, i))) {
      out.insert(0, i);
    }
  }
  return out;
}

String grupoAulaVagasLabel({
  required int inscritos,
  required int capacidadeMax,
}) {
  if (capacidadeMax <= 0) return 'Sem vagas';
  if (inscritos >= capacidadeMax) return 'Lotada';
  final livres = capacidadeMax - inscritos;
  if (livres == 1) return '1 vaga';
  return '$livres vagas';
}

String grupoAulaSubtitle({
  required DateTime inicio,
  String? localAula,
}) {
  final when = grupoAulaWhenLabel(inicio);
  final local = localAula?.trim();
  if (local == null || local.isEmpty) return when;
  return '$when · $local';
}

bool grupoAulaLotada({
  required int inscritos,
  required int capacidadeMax,
}) =>
    capacidadeMax > 0 && inscritos >= capacidadeMax;

String grupoAulaFxIcon({
  required int inscritos,
  required int capacidadeMax,
}) =>
    grupoAulaLotada(inscritos: inscritos, capacidadeMax: capacidadeMax)
        ? 'alert-triangle'
        : 'calendar';

String grupoAulaHubSubtitle(String? freshness) {
  const base = 'Turmas abertas e vagas';
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

enum GrupoAulaChip { todas, abertas, lotadas }

String grupoAulaCountLabel(int count) {
  if (count <= 0) return 'Nenhuma aula';
  if (count == 1) return '1 aula';
  return '$count aulas';
}

String grupoAulaChipLabel(GrupoAulaChip chip) => switch (chip) {
  GrupoAulaChip.todas => 'Todas',
  GrupoAulaChip.abertas => 'Abertas',
  GrupoAulaChip.lotadas => 'Lotadas',
};

bool grupoAulaMatches({
  required String titulo,
  required String? localAula,
  required bool lotada,
  required String query,
  required GrupoAulaChip chip,
}) {
  final matchesChip = switch (chip) {
    GrupoAulaChip.todas => true,
    GrupoAulaChip.abertas => !lotada,
    GrupoAulaChip.lotadas => lotada,
  };
  if (!matchesChip) return false;
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  if (titulo.toLowerCase().contains(q)) return true;
  final local = localAula?.toLowerCase() ?? '';
  return local.contains(q);
}
