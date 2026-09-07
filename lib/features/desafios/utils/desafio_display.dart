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
