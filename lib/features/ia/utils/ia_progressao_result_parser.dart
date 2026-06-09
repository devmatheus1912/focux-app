/// Parses IA markdown progressão responses into mobile-friendly exercise rows.
class IaProgressaoExerciseRow {
  const IaProgressaoExerciseRow({
    required this.exercicio,
    required this.cargaAtual,
    required this.cargaSugerida,
    required this.justificativa,
  });

  final String exercicio;
  final String cargaAtual;
  final String cargaSugerida;
  final String justificativa;
}

class IaProgressaoParsedResult {
  const IaProgressaoParsedResult({
    required this.rawMarkdown,
    this.intro,
    this.exercises = const [],
    this.footer,
  });

  final String rawMarkdown;
  final String? intro;
  final List<IaProgressaoExerciseRow> exercises;
  final String? footer;

  bool get hasStructuredRows => exercises.isNotEmpty;

  String toPlainText() {
    if (!hasStructuredRows) return rawMarkdown.trim();

    final buf = StringBuffer();
    final introText = intro?.trim();
    if (introText != null && introText.isNotEmpty) {
      buf.writeln(introText);
      buf.writeln();
    }
    for (final e in exercises) {
      buf.writeln(e.exercicio);
      buf.writeln('  Atual: ${e.cargaAtual}');
      buf.writeln('  Sugerido: ${e.cargaSugerida}');
      if (e.justificativa.isNotEmpty) {
        buf.writeln('  ${e.justificativa}');
      }
      buf.writeln();
    }
    final footerText = footer?.trim();
    if (footerText != null && footerText.isNotEmpty) {
      buf.writeln(footerText);
    }
    return buf.toString().trim();
  }
}

IaProgressaoParsedResult parseIaProgressaoMarkdown(String raw) {
  final normalized = raw.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) {
    return IaProgressaoParsedResult(rawMarkdown: raw);
  }

  final lines = normalized.split('\n');
  final preTable = <String>[];
  final tableLines = <String>[];
  final postTable = <String>[];

  var inTable = false;
  var tableEnded = false;

  for (final line in lines) {
    final trimmed = line.trim();
    if (_isTableLine(trimmed)) {
      inTable = true;
      tableLines.add(trimmed);
      continue;
    }
    if (inTable) {
      tableEnded = true;
      if (trimmed.isNotEmpty) postTable.add(trimmed);
    } else if (trimmed.isNotEmpty) {
      preTable.add(trimmed);
    }
  }

  if (!tableEnded && inTable) {
    // Entire response was a table — no footer.
  } else if (!inTable) {
    postTable.clear();
  }

  final exercises = <IaProgressaoExerciseRow>[];
  for (final line in tableLines) {
    if (_isTableSeparator(line)) continue;
    final cells = _parseTableCells(line);
    if (cells.isEmpty || _looksLikeHeader(cells)) continue;
    final row = _mapCellsToExercise(cells);
    if (row != null) exercises.add(row);
  }

  return IaProgressaoParsedResult(
    rawMarkdown: raw,
    intro: preTable.isEmpty ? null : _cleanMarkdownParagraph(preTable.join('\n')),
    exercises: exercises,
    footer:
        postTable.isEmpty ? null : _cleanMarkdownParagraph(postTable.join('\n')),
  );
}

bool _isTableLine(String line) =>
    line.contains('|') &&
    line.split('|').where((c) => c.trim().isNotEmpty).length >= 2;

bool _isTableSeparator(String line) {
  final cells = _parseTableCells(line);
  if (cells.isEmpty) return false;
  return cells.every((c) => RegExp(r'^:?-{2,}:?$').hasMatch(c.trim()));
}

List<String> _parseTableCells(String line) {
  var s = line.trim();
  if (s.startsWith('|')) s = s.substring(1);
  if (s.endsWith('|')) s = s.substring(0, s.length - 1);
  return s.split('|').map((c) => c.trim()).toList();
}

bool _looksLikeHeader(List<String> cells) {
  final joined = cells.map((c) => c.toLowerCase()).join(' ');
  return joined.contains('exerc') ||
      joined.contains('carga atual') ||
      joined.contains('sugerid') ||
      joined.contains('justific');
}

IaProgressaoExerciseRow? _mapCellsToExercise(List<String> cells) {
  final nonEmpty = cells.where((c) => c.trim().isNotEmpty).toList();
  if (nonEmpty.length < 2 || _looksLikeHeader(nonEmpty)) return null;

  if (nonEmpty.length >= 4) {
    return IaProgressaoExerciseRow(
      exercicio: _stripInlineMarkdown(nonEmpty[0]),
      cargaAtual: _stripInlineMarkdown(nonEmpty[1]),
      cargaSugerida: _stripInlineMarkdown(nonEmpty[2]),
      justificativa: _stripInlineMarkdown(nonEmpty.sublist(3).join(' ')),
    );
  }
  if (nonEmpty.length == 3) {
    return IaProgressaoExerciseRow(
      exercicio: _stripInlineMarkdown(nonEmpty[0]),
      cargaAtual: _stripInlineMarkdown(nonEmpty[1]),
      cargaSugerida: _stripInlineMarkdown(nonEmpty[2]),
      justificativa: '',
    );
  }
  return IaProgressaoExerciseRow(
    exercicio: _stripInlineMarkdown(nonEmpty[0]),
    cargaAtual: _stripInlineMarkdown(nonEmpty[1]),
    cargaSugerida: '',
    justificativa: '',
  );
}

String _stripInlineMarkdown(String value) =>
    value.replaceAll('**', '').replaceAll('*', '').replaceAll('`', '').trim();

String _cleanMarkdownParagraph(String value) {
  return value
      .split('\n')
      .map(
        (line) => line
            .replaceAll(RegExp(r'^#+\s*'), '')
            .replaceAll('**', '')
            .trim(),
      )
      .where((line) => line.isNotEmpty)
      .join('\n')
      .trim();
}
