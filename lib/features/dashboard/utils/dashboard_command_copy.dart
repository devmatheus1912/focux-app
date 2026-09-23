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
    text = text.replaceAllMapped(RegExp(pair.$1, caseSensitive: false), (
      match,
    ) {
      final word = match.group(0)!;
      final capitalized = word[0].toUpperCase() == word[0];
      return capitalized ? pair.$3 : pair.$2;
    });
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

/// Rótulo com contagem e plural correto em PT (ex.: 1 cobrança pendente / 3 cobranças pendentes).
String dashboardCountLabel(int count, String singular, String plural) {
  if (count <= 0) return plural;
  if (count == 1) return '1 $singular';
  return '$count $plural';
}

/// Corrige descrições do backend com contagem + plural (ex. "1 cobranças pendentes").
String dashboardFormatCountCopy(String raw) {
  var text = dashboardFormatActionCopy(raw);
  final cobranca = RegExp(
    r'^(\d+)\s+cobran[cç]as?\s+pendentes?$',
    caseSensitive: false,
  ).firstMatch(text.trim());
  if (cobranca != null) {
    final n = int.tryParse(cobranca.group(1)!) ?? 0;
    return dashboardCountLabel(n, 'cobrança pendente', 'cobranças pendentes');
  }
  final mensalidade = RegExp(
    r'^(\d+)\s+mensalidades?\s+',
    caseSensitive: false,
  ).firstMatch(text.trim());
  if (mensalidade != null) {
    final n = int.tryParse(mensalidade.group(1)!) ?? 0;
    final rest = text.substring(mensalidade.end).trim();
    final head = dashboardCountLabel(n, 'mensalidade', 'mensalidades');
    return rest.isEmpty ? head : '$head $rest';
  }
  return text;
}

const kDashboardActionCopyMaxChars = 72;

/// Subtítulo da fila: corta narrativa longa sem estourar o tile.
String dashboardClampActionCopy(
  String raw, {
  int maxChars = kDashboardActionCopyMaxChars,
}) {
  var text = dashboardFormatCountCopy(raw).trim();
  text = text.replaceAll('`', '');
  text = text.replaceFirst(
    RegExp(r'clicou\s+\d+\s+vezes?\s+em\s+', caseSensitive: false),
    '',
  );
  text = text
      .replaceFirst(
        RegExp(r'\s*[·—–-]\s*Pr[oó]xima a[cç][aã]o:.*$', caseSensitive: false),
        '',
      )
      .trim();
  if (text.length <= maxChars) return text;
  var cut = text.lastIndexOf(' ', maxChars);
  if (cut < (maxChars / 2)) cut = maxChars;
  return '${text.substring(0, cut).trimRight()}…';
}

/// Ação curta a partir de motivo / proximaAcao (espelha BE `acaoCurta`).
String dashboardRiskActionHint(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return 'contato hoje';
  final lower = text.toLowerCase();
  if (lower.contains('mapa') || lower.contains('corporal')) {
    return 'mapa corporal';
  }
  if (lower.contains('financeir') || lower.contains('mensalidade')) {
    return 'pendência financeira';
  }
  if (lower.contains('treino') ||
      lower.contains('check-in') ||
      lower.contains('check in')) {
    return 'retomar treino';
  }
  if (lower.contains('feedback')) return 'pedir feedback';
  if (lower.contains('medida')) return 'solicitar medida';
  if (lower.contains('abandono') || lower.contains('risco')) {
    return 'contato hoje';
  }
  return dashboardClampActionCopy(text, maxChars: 36).toLowerCase();
}

/// Subtítulo do sheet «Ações por aluno» — lead + copy distinto por aluno.
String dashboardRiskStudentSheetSubtitle({
  required bool isLead,
  String? motivo,
  String? nivelRisco,
  String? proximaAcao,
  String? filaHint,
}) {
  final hint =
      (filaHint != null && filaHint.trim().isNotEmpty)
          ? dashboardClampActionCopy(filaHint, maxChars: 40)
          : (proximaAcao != null && proximaAcao.trim().isNotEmpty)
          ? dashboardRiskActionHint(proximaAcao)
          : (motivo != null && motivo.trim().isNotEmpty)
          ? dashboardRiskActionHint(motivo)
          : _riskLevelHint(nivelRisco);

  if (isLead) {
    return hint == null || hint.isEmpty
        ? 'Comece por aqui'
        : 'Comece por aqui · $hint';
  }
  return hint == null || hint.isEmpty ? 'Contato e retenção' : hint;
}

String? _riskLevelHint(String? nivelRisco) {
  final n = (nivelRisco ?? '').trim().toUpperCase();
  if (n.isEmpty) return null;
  if (n.contains('ALTO') || n == 'ALTA') return 'risco alto · contato hoje';
  if (n.contains('MEDIO') || n.contains('MÉDIO') || n == 'MEDIA') {
    return 'risco médio · acompanhar';
  }
  if (n.contains('BAIXO') || n == 'BAIXA') return 'acompanhar retenção';
  return null;
}
