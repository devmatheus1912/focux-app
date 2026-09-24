/// Normaliza texto de OCR/cópia antes do parser linha-a-linha no backend.
class MigracaoTextoNormalizer {
  MigracaoTextoNormalizer._();

  static final _emailRe = RegExp(
    r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
    caseSensitive: false,
  );

  /// Prepara texto para `POST /api/v1/migracao/texto` (1 linha ≈ 1 aluno).
  static String normalizeForImport(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!_looksLikeFragmentedOcr(trimmed)) {
      return trimmed;
    }

    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ').trim();
    final rows = _rowsSplitByEmail(collapsed);
    if (rows.length >= 2) {
      return rows.join('\n');
    }
    if (rows.length == 1 && rows.first != collapsed) {
      return rows.first;
    }
    return collapsed;
  }

  /// OCR vertical: muitas linhas curtas sem e-mail/telefone.
  static bool looksLikeFragmentedOcr(String raw) =>
      _looksLikeFragmentedOcr(raw.trim());

  static bool _looksLikeFragmentedOcr(String text) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 3) return false;

    var wordTotal = 0;
    for (final line in lines) {
      wordTotal += line.split(RegExp(r'\s+')).length;
    }
    final avgWords = wordTotal / lines.length;

    // Lista real: ~1 aluno por linha com vários tokens; OCR vertical: ~1 palavra/linha.
    return avgWords <= 1.6;
  }

  static List<String> _rowsSplitByEmail(String collapsed) {
    final matches = _emailRe.allMatches(collapsed).toList();
    if (matches.isEmpty) return [collapsed];

    final rows = <String>[];

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final prevEnd =
          i == 0 ? 0 : _consumeThroughPhone(collapsed, matches[i - 1].end);
      final name = collapsed.substring(prevEnd, match.start).trim();
      final email = match.group(0)!;
      final phone = _phoneAfter(collapsed, match.end);

      final parts = <String>[
        if (name.isNotEmpty) name,
        email,
        if (phone.isNotEmpty) phone,
      ];
      rows.add(parts.join(' '));
    }

    return rows.where((r) => r.isNotEmpty).toList();
  }

  /// Index after optional phone that follows [from] (skips spaces).
  static int _consumeThroughPhone(String text, int from) {
    var i = from;
    while (i < text.length && text[i] == ' ') {
      i++;
    }
    final digitStart = i;
    while (i < text.length && _isDigit(text[i])) {
      i++;
    }
    final digits = i - digitStart;
    if (digits >= 10 && digits <= 13) {
      return i;
    }
    return from;
  }

  static String _phoneAfter(String text, int from) {
    final end = _consumeThroughPhone(text, from);
    if (end <= from) return '';
    final slice = text.substring(from, end).trim();
    return slice;
  }

  static bool _isDigit(String char) {
    final code = char.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}
