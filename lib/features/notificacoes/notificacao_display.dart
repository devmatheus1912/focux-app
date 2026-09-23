const notificacaoComoCalculamos =
    'Avisos operacionais do estúdio: mensalidade, feed, trial e Radar. Mensagens de chat ficam só na inbox de chat.';

String notificacaoCountLabel(int count) {
  if (count <= 0) return 'Nenhuma';
  if (count == 1) return '1 aviso';
  return '$count avisos';
}

String notificacaoSearchEmptyTitle(String query) =>
    query.trim().isEmpty ? 'Tudo em ordem' : 'Nenhum aviso encontrado';

String notificacaoSearchEmptySubtitle(String query) => query.trim().isEmpty
    ? 'Alertas financeiros, novidades do feed e sinais do Radar aparecem aqui.'
    : 'Nada com esse texto nesta caixa.';

const _nameParticles = {'de', 'da', 'do', 'dos', 'das', 'e'};

/// Title-case person names from API payloads (e.g. `thales` → `Thales`).
String formatDisplayName(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;

  return trimmed
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return word;
        final lower = word.toLowerCase();
        if (_nameParticles.contains(lower)) return lower;
        if (lower.length == 1) return lower.toUpperCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

String normalizeNotificationText(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

/// Collapses duplicate Radar rows (same aluno + mesma ação + mesma rota).
String radarSignalDedupeKey({
  required String displayName,
  required String summary,
  String route = '',
}) {
  return [
    normalizeNotificationText(displayName),
    normalizeNotificationText(summary),
    normalizeNotificationText(route),
  ].join('|');
}
