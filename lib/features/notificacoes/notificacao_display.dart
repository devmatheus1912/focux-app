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
