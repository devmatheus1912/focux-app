import 'dart:convert';

const exerciseMediaImportTemplate =
    'importKey,videoUrl,thumbnailUrl,videoSource,licenseStatus\n'
    'supino-reto-peso-corporal-iniciante-hipertrofia|peito|peso-corporal,'
    'https://cdn.exemplo/supino.mp4,'
    'https://cdn.exemplo/supino.jpg,'
    'FOCUX_LIBRARY,'
    'LICENSED\n';

List<Map<String, dynamic>> parseExerciseMediaImportPayload(String raw) {
  final content = raw.trim();
  if (content.isEmpty) {
    throw Exception('conteudo vazio');
  }
  if (content.startsWith('{') || content.startsWith('[')) {
    final decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    if (decoded is Map && decoded['midias'] is List) {
      return (decoded['midias'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    throw Exception('JSON precisa ser lista ou objeto com midias');
  }
  return parseExerciseMediaCsv(content);
}

List<Map<String, dynamic>> parseExerciseMediaCsv(String raw) {
  final delimiter = _detectDelimiter(raw);
  final rows = _parseCsvRows(raw, delimiter)
      .where((row) => row.any((cell) => cell.trim().isNotEmpty))
      .toList();
  if (rows.length < 2) {
    throw Exception('CSV precisa de cabecalho e ao menos uma linha');
  }

  final headers = rows.first.map((e) => e.trim()).toList();
  if (headers.any((header) => header.isEmpty)) {
    throw Exception('CSV tem cabecalho vazio');
  }
  if (!headers.contains('importKey') && !headers.contains('nome')) {
    throw Exception('CSV precisa de importKey ou nome');
  }

  return [
    for (final row in rows.skip(1))
      {
        for (var i = 0; i < headers.length; i++)
          if (i < row.length && row[i].trim().isNotEmpty)
            headers[i]: row[i].trim(),
      },
  ];
}

String _detectDelimiter(String raw) {
  final firstLine = raw.split(RegExp(r'\r?\n')).first;
  final commaCount = ','.allMatches(firstLine).length;
  final semicolonCount = ';'.allMatches(firstLine).length;
  return semicolonCount > commaCount ? ';' : ',';
}

List<List<String>> _parseCsvRows(String raw, String delimiter) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < raw.length; i++) {
    final char = raw[i];
    final next = i + 1 < raw.length ? raw[i + 1] : null;

    if (char == '"') {
      if (inQuotes && next == '"') {
        field.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (!inQuotes && char == delimiter) {
      row.add(field.toString());
      field.clear();
      continue;
    }

    if (!inQuotes && (char == '\n' || char == '\r')) {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
      if (char == '\r' && next == '\n') {
        i++;
      }
      continue;
    }

    field.write(char);
  }

  if (inQuotes) {
    throw Exception('CSV tem aspas nao fechadas');
  }

  row.add(field.toString());
  rows.add(row);
  return rows;
}
