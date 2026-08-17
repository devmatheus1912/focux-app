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

  static String? fromFetchedAt(DateTime? fetchedAt, {DateTime? now}) {
    if (fetchedAt == null) return null;
    return atualizadoHa((now ?? DateTime.now()).difference(fetchedAt));
  }
}
