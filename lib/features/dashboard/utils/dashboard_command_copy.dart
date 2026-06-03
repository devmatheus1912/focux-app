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

final RegExp _radarFocuxTitlePattern = RegExp(
  r'^Radar Focux:\s*(.+)$',
  caseSensitive: false,
);

bool dashboardIsRadarFocuxTitle(String rawTitle) =>
    _radarFocuxTitlePattern.hasMatch(rawTitle.trim());

/// Nome do aluno para título do sheet (sem prefixo "Radar Focux").
String? dashboardRadarStudentName(String rawTitle) {
  final match = _radarFocuxTitlePattern.firstMatch(rawTitle.trim());
  if (match == null) return null;
  return fxTitleCaseName(match.group(1)!.trim());
}

/// Badge curto para scan (P0, P1, Hoje…).
String? dashboardPriorityBadgeLabel({
  required String prioridade,
  String? sla,
  String? ctaLabel,
}) {
  final p = prioridade.trim().toUpperCase();
  if (p == 'P0' || p == 'P1' || p == 'P2') return p;
  final slaNorm = (sla ?? '').trim().toLowerCase();
  if (slaNorm == 'hoje') return 'Hoje';
  final cta = (ctaLabel ?? '').trim();
  if (cta.isNotEmpty && cta.length <= 12) return cta;
  return null;
}

/// Subtítulo do radar no sheet: badge + descrição sem repetir o nome.
String dashboardRadarSheetSubtitle({
  required String descricao,
  String? prioridade,
  String? sla,
  String? ctaLabel,
}) {
  final badge = dashboardPriorityBadgeLabel(
    prioridade: prioridade ?? '',
    sla: sla,
    ctaLabel: ctaLabel,
  );
  final body = dashboardFormatActionCopy(descricao);
  if (badge == null || badge.isEmpty) return body;
  return '$badge · $body';
}
