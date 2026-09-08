import '../../../core/utils/fx_utils.dart';

const desafioTipos = <({String value, String label})>[
  (value: 'HABITOS', label: 'Hábitos'),
  (value: 'TREINOS', label: 'Treinos'),
];

const desafioDuracoes = <int>[7, 14, 30, 60];

String desafioTipoLabel(String tipo) {
  final key = tipo.trim().toUpperCase();
  for (final item in desafioTipos) {
    if (item.value == key) return item.label;
  }
  return key.isEmpty ? 'Hábitos' : tipo.trim();
}

String desafioDuracaoLabel(int dias) {
  if (dias == 1) return '1 dia';
  return '$dias dias';
}

String desafioHubSubtitle({required int count, String? freshness}) {
  final base = desafioCountLabel(count);
  final stamp = freshness?.trim();
  if (stamp == null || stamp.isEmpty) return base;
  return '$base · $stamp';
}

String desafioCountLabel(int count) {
  if (count <= 0) return 'Nenhum desafio';
  if (count == 1) return '1 desafio';
  return '$count desafios';
}

String desafioSubtitle({
  required String tipo,
  required int metaPontos,
  DateTime? inicio,
  DateTime? fim,
}) {
  final prazo = desafioPrazoLabel(inicio: inicio, fim: fim);
  final kind = desafioTipoLabel(tipo);
  if (prazo.isEmpty) return '$kind · meta $metaPontos pts';
  return '$prazo · $kind · $metaPontos pts';
}

String desafioPrazoLabel({DateTime? inicio, DateTime? fim}) {
  if (inicio == null && fim == null) return '';
  if (inicio != null && fim != null) {
    return '${fxDateShort(inicio)} – ${fxDateShort(fim)}';
  }
  if (fim != null) return 'até ${fxDateShort(fim)}';
  return 'desde ${fxDateShort(inicio!)}';
}

String desafioLeaderboardEmpty() => 'Nenhum participante com pontos ainda.';

String desafioLeaderboardName(String? nome) {
  final value = nome?.trim();
  if (value == null || value.isEmpty) return 'Aluno';
  return value;
}

String desafioLeaderboardPoints(Object? pontos) => '${pontos ?? 0} pts';

String desafioMetaLabel(int metaPontos) => '$metaPontos pts';

enum DesafioTipoFiltro { todos, habitos, treinos }

String desafioFiltroLabel(DesafioTipoFiltro filtro) => switch (filtro) {
  DesafioTipoFiltro.todos => 'Todos',
  DesafioTipoFiltro.habitos => 'Hábitos',
  DesafioTipoFiltro.treinos => 'Treinos',
};

bool desafioMatchesFiltro(String tipo, DesafioTipoFiltro filtro) {
  if (filtro == DesafioTipoFiltro.todos) return true;
  final key = tipo.trim().toUpperCase();
  return filtro == DesafioTipoFiltro.habitos
      ? key == 'HABITOS'
      : key == 'TREINOS';
}

String desafioDetailPath(int id) => '/desafios/$id';

String desafioAlunoDetailPath(int id) => '/aluno/desafios/$id';

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

int desafioDiasRestantes(DateTime? fim, {DateTime? now}) {
  if (fim == null) return 0;
  return _dateOnly(fim).difference(_dateOnly(now ?? DateTime.now())).inDays;
}

String desafioDiasRestantesValue(DateTime? fim, {DateTime? now}) {
  if (fim == null) return '—';
  final days = desafioDiasRestantes(fim, now: now);
  if (days < 0) return 'Encerrado';
  if (days == 0) return 'Hoje';
  return '$days';
}

String desafioDiasRestantesHint(DateTime? fim, {DateTime? now}) {
  if (fim == null) return 'Sem prazo';
  final days = desafioDiasRestantes(fim, now: now);
  if (days < 0) return 'Fora do prazo';
  if (days == 0) return 'Último dia';
  if (days == 1) return '1 dia restante';
  return '$days dias restantes';
}

String desafioParticipantesValue(int count) => '$count';

String desafioParticipantesHint(int count) {
  if (count <= 0) return 'Ninguém no ranking';
  if (count == 1) return '1 participante';
  return '$count participantes';
}

int desafioAtingiramMeta(Iterable<int> pontos, int metaPontos) =>
    pontos.where((p) => p >= metaPontos).length;

String desafioMetaAtingidaValue({required int atingiram, required int total}) =>
    '$atingiram/$total';

String desafioMetaAtingidaHint(int metaPontos) =>
    'Chegaram em ${desafioMetaLabel(metaPontos)}';

String desafioDetailSubtitle({
  required String tipo,
  DateTime? fim,
  String? freshness,
}) {
  final parts = <String>[desafioTipoLabel(tipo)];
  final prazo = desafioDiasRestantesHint(fim);
  if (prazo.isNotEmpty) parts.add(prazo);
  final stamp = freshness?.trim();
  if (stamp != null && stamp.isNotEmpty) parts.add(stamp);
  return parts.join(' · ');
}

String desafioStickyEncerrarLabel() => 'Encerrar desafio';

String desafioStickyAlunoLabel(String tipo) =>
    tipo.trim().toUpperCase() == 'TREINOS' ? 'Ir aos treinos' : 'Ir aos hábitos';

String desafioStickyAlunoPath(String tipo) =>
    tipo.trim().toUpperCase() == 'TREINOS'
        ? '/checkin/treinos'
        : '/aluno/habitos';

String desafioLugarLabel(int index) => '${index + 1}º lugar';
