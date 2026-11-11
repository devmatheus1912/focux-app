/// Freshness labels — same rules as Home (`DashboardMicrocopy.atualizadoHa`).
abstract final class FxHubFreshness {
  FxHubFreshness._();

  static String atualizadoHa(Duration age) {
    final secs = age.inSeconds;
    if (secs < 15) return 'Atualizado agora';
    if (secs < 60) return 'Atualizado há ${secs}s';
    final mins = age.inMinutes;
    if (mins < 60) return 'Atualizado há ${mins}min';
    final hours = age.inHours;
    return 'Atualizado há ${hours}h';
  }

  /// Abaixo disso o dado é novo e "Atualizado agora" só ocupa o topo.
  static const silencio = Duration(minutes: 5);

  /// Frescor para o subtítulo das telas: só aparece quando o dado já tem
  /// mais de [silencio]; antes disso, `null` (o topo fica com o resto).
  static String? fromFetchedAt(DateTime? fetchedAt, {DateTime? now}) {
    if (fetchedAt == null) return null;
    final idade = (now ?? DateTime.now()).difference(fetchedAt);
    if (idade < silencio) return null;
    return atualizadoHa(idade);
  }

  /// Subtítulo S4: contagem e freshness no mesmo papel, separados por ` · `.
  static String joinCount(String countLabel, String? freshness) {
    final stamp = freshness?.trim();
    if (stamp == null || stamp.isEmpty) return countLabel;
    return '$countLabel · $stamp';
  }
}
