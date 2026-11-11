String grupoAulaDateLabel(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '$day/$month';
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

bool grupoAulaLotada({required int inscritos, required int capacidadeMax}) =>
    capacidadeMax > 0 && inscritos >= capacidadeMax;

/// O que a linha da aula faz, à direita: "Inscrito", "Inscrever" ou "Lotada".
String grupoAulaStatusLabel({required bool inscrito, required bool lotada}) {
  if (inscrito) return 'Inscrito';
  if (lotada) return 'Lotada';
  return 'Inscrever';
}

/// Vagas no subtítulo só quando restam poucas ("3 vagas"); senão nada.
String? grupoAulaPoucasVagas({
  required int inscritos,
  required int capacidadeMax,
}) {
  if (capacidadeMax <= 0) return null;
  final livres = capacidadeMax - inscritos;
  if (livres <= 0 || livres > 3) return null;
  return livres == 1 ? '1 vaga' : '$livres vagas';
}

/// Busca só quando ajuda (mesma regra do Feedback em vídeo e das mensalidades).
const grupoAulaBuscaMinimo = 6;

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

String? grupoAulaChipQuery(GrupoAulaChip chip) => switch (chip) {
  GrupoAulaChip.todas => null,
  GrupoAulaChip.abertas => 'ABERTAS',
  GrupoAulaChip.lotadas => 'LOTADAS',
};

/// Mesmo teto do servidor (`CAPACIDADE_MAX_LIMITE`).
const grupoAulaCapacidadeLimite = 200;

const _semana = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'];

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// "qui., 11/11".
String grupoAulaDiaLabel(DateTime d) =>
    '${_semana[d.weekday - 1]}, ${grupoAulaDateLabel(d)}';

/// "07:00 – 08:00".
String grupoAulaHorarioLabel(DateTime inicio, DateTime fim) =>
    '${_hm(inicio)} – ${_hm(fim)}';

/// "qui. 11/11 · 07:00 – 08:00 · Studio".
String grupoAulaLinha({
  required DateTime inicio,
  required DateTime fim,
  String? localAula,
}) {
  final local = localAula?.trim();
  return [
    '${_semana[inicio.weekday - 1]} ${grupoAulaDateLabel(inicio)}',
    grupoAulaHorarioLabel(inicio, fim),
    if (local != null && local.isNotEmpty) local,
  ].join(' · ');
}

/// "12/20" para o personal; "Lotada" quando enche; "Cancelada".
String grupoAulaOcupacaoLabel({
  required int inscritos,
  required int capacidadeMax,
  required String status,
}) {
  if (status == 'CANCELADA') return 'Cancelada';
  if (grupoAulaLotada(inscritos: inscritos, capacidadeMax: capacidadeMax)) {
    return 'Lotada';
  }
  return '$inscritos/$capacidadeMax';
}

String grupoAulaAlunosEscolhidosLabel(int n) => switch (n) {
  0 => 'Nenhum',
  1 => '1 aluno',
  _ => '$n alunos',
};

/// "Hoje", "Amanhã", "Em 5 dias".
String grupoAulaDiaRelativo(DateTime dia, DateTime hoje) {
  final d = DateTime(dia.year, dia.month, dia.day);
  final h = DateTime(hoje.year, hoje.month, hoje.day);
  final n = d.difference(h).inDays;
  if (n == 0) return 'Hoje';
  if (n == 1) return 'Amanhã';
  if (n < 0) return 'Já passou';
  return 'Em $n dias';
}

/// Durações da aula em grupo, em minutos (padrão 1 h).
const grupoAulaDuracoes = [30, 45, 60, 90];
const grupoAulaDuracaoPadrao = 60;

/// "30 min", "1 h", "1 h 30".
String grupoAulaDuracaoLabel(int minutos) {
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '$h h' : '$h h ${m.toString().padLeft(2, '0')}';
}

/// Duração gravada que não é uma das quatro: aparece como opção a mais.
int? grupoAulaDuracaoFora(int minutos) =>
    minutos > 0 && !grupoAulaDuracoes.contains(minutos) ? minutos : null;
