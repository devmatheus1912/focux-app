/// Normalizes progressão inputs before IA and persistence.
String normalizeIaProgressaoObjetivo(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
}

String normalizeIaProgressaoHistorico(String raw) {
  if (raw.trim().isEmpty) return '';

  final parts = raw.split(RegExp(r'[,;\n]+'));
  final normalized = parts
      .map((part) => _normalizeExerciseLine(part.trim()))
      .where((part) => part.isNotEmpty)
      .join(', ');

  return normalized;
}

bool iaProgressaoHistoricoWasNormalized(String raw, String normalized) =>
    raw.trim() != normalized.trim();

String _normalizeExerciseLine(String line) {
  if (line.isEmpty) return '';

  var text = line.replaceAll(RegExp(r'\s+'), ' ');

  text = text.replaceAllMapped(
    RegExp(r'(\d+)\s*[-–×xX]\s*(\d+)', caseSensitive: false),
    (m) => '${m[1]}x${m[2]}',
  );

  text = text.replaceAllMapped(
    RegExp(r'(\d+(?:[,.]\d+)?)\s*[-–]?\s*kg', caseSensitive: false),
    (m) => '${m[1]!.replaceAll(',', '.')}kg',
  );

  for (final entry in _exerciseTypoFixes.entries) {
    text = text.replaceAll(
      RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
      entry.value,
    );
  }

  return text.trim();
}

const _exerciseTypoFixes = {
  'supni': 'Supino',
  'supin': 'Supino',
  'agachamneto': 'Agachamento',
  'agachamento livre': 'Agachamento',
  'leg press': 'Leg press',
  'rosca direat': 'Rosca direta',
  'desenvolvimento': 'Desenvolvimento',
};
