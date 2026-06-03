import '../../../core/utils/fx_utils.dart';

/// Normaliza microcopy vinda do backend (ASCII) para PT-BR legível na UI.
String dashboardFormatActionCopy(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;

  var text = trimmed;
  for (final pair in const [
    (r'\bacao\b', 'ação', 'Ação'),
    (r'\bproxima\b', 'próxima', 'Próxima'),
    (r'\brecomendacao\b', 'recomendação', 'Recomendação'),
    (r'\boperacao\b', 'operação', 'Operação'),
    (r'\bevolucao\b', 'evolução', 'Evolução'),
  ]) {
    text = text.replaceAllMapped(
      RegExp(pair.$1, caseSensitive: false),
      (match) {
        final word = match.group(0)!;
        final capitalized = word[0].toUpperCase() == word[0];
        return capitalized ? pair.$3 : pair.$2;
      },
    );
  }

  final radar = RegExp(r'^Radar Focux:\s*(.+)$', caseSensitive: false);
  final match = radar.firstMatch(text);
  if (match != null) {
    final nome = fxTitleCaseName(match.group(1)!.trim());
    return 'Radar Focux: $nome';
  }

  return text;
}
