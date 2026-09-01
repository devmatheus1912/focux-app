String grupoAulaWhenLabel(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final hour = d.hour.toString().padLeft(2, '0');
  final minute = d.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
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
