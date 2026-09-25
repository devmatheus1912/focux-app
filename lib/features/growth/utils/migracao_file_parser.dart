import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../models/migracao_aluno_linha.dart';

/// Resultado ao importar CSV/XLSX/TXT para a Migração Focux.
class MigracaoFileParseResult {
  const MigracaoFileParseResult({
    this.directAlunos,
    this.textForIa,
    required this.sourceLabel,
  });

  /// Planilha estruturada — vai direto para preview sem IA.
  final List<MigracaoAlunoLinha>? directAlunos;

  /// Texto para colar/processar com IA.
  final String? textForIa;

  final String sourceLabel;

  bool get usesDirectParse => directAlunos != null && directAlunos!.isNotEmpty;
}

class MigracaoFileParser {
  MigracaoFileParser._();

  static MigracaoFileParseResult parse({
    required Uint8List bytes,
    required String filename,
  }) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.xlsx')) {
      return _parseXlsx(bytes, filename);
    }
    final text = _decodeText(bytes);
    if (lower.endsWith('.csv') || _looksLikeCsv(text)) {
      return _parseCsvText(text, filename);
    }
    return MigracaoFileParseResult(
      textForIa: text.trim(),
      sourceLabel: filename,
    );
  }

  static String _decodeText(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static bool _looksLikeCsv(String text) {
    final lines =
        text.split('\n').where((l) => l.trim().isNotEmpty).take(3).toList();
    if (lines.isEmpty) return false;
    return lines.any((line) => line.contains(',') || line.contains(';'));
  }

  static MigracaoFileParseResult _parseCsvText(String text, String filename) {
    final delimiter = text.contains(';') && !text.contains(',') ? ';' : ',';
    final rows = Csv(
      fieldDelimiter: delimiter,
      lineDelimiter: '\n',
      autoDetect: false,
    ).decode(text);

    final parsed = _rowsToAlunos(rows);
    if (parsed != null && parsed.isNotEmpty) {
      return MigracaoFileParseResult(
        directAlunos: parsed,
        sourceLabel: filename,
      );
    }

    return MigracaoFileParseResult(
      textForIa: text.trim(),
      sourceLabel: filename,
    );
  }

  static MigracaoFileParseResult _parseXlsx(Uint8List bytes, String filename) {
    try {
      final book = Excel.decodeBytes(bytes);
      if (book.tables.isEmpty) {
        return MigracaoFileParseResult(textForIa: '', sourceLabel: filename);
      }
      final sheet = book.tables.values.first;
      final rows = <List<dynamic>>[];
      for (final row in sheet.rows) {
        rows.add(row.map((cell) => cell?.value?.toString() ?? '').toList());
      }
      final parsed = _rowsToAlunos(rows);
      if (parsed != null && parsed.isNotEmpty) {
        return MigracaoFileParseResult(
          directAlunos: parsed,
          sourceLabel: filename,
        );
      }

      final buffer = StringBuffer();
      for (final row in rows) {
        final line = row
            .map((v) => v.toString().trim())
            .where((v) => v.isNotEmpty)
            .join(' — ');
        if (line.isNotEmpty) buffer.writeln(line);
      }
      return MigracaoFileParseResult(
        textForIa: buffer.toString().trim(),
        sourceLabel: filename,
      );
    } catch (_) {
      return MigracaoFileParseResult(
        textForIa: _decodeText(bytes).trim(),
        sourceLabel: filename,
      );
    }
  }

  static List<MigracaoAlunoLinha>? _rowsToAlunos(List<List<dynamic>> rows) {
    if (rows.isEmpty) return null;

    final header = rows.first.map((c) => _norm(c.toString())).toList();
    final nomeIdx = _indexFor(header, ['nome', 'name', 'aluno', 'cliente']);
    final emailIdx = _indexFor(header, ['email', 'e mail', 'e-mail', 'mail']);
    final telIdx = _indexFor(header, [
      'telefone',
      'celular',
      'whatsapp',
      'phone',
      'tel',
      'fone',
    ]);
    final objIdx = _indexFor(header, ['objetivo', 'goal', 'meta', 'objetivos']);

    final hasRecognizedHeader =
        nomeIdx != null || emailIdx != null || telIdx != null;

    if (rows.length > 1 && hasRecognizedHeader) {
      // cabeçalho mapeado — parse estruturado
    } else if (!hasRecognizedHeader) {
      final anyEmail = rows.any(
        (row) => row.any((cell) => cell.toString().contains('@')),
      );
      if (!anyEmail) return null;
    } else {
      return null;
    }

    final start = hasRecognizedHeader ? 1 : 0;

    if (hasRecognizedHeader && nomeIdx == null && emailIdx == null) {
      return null;
    }

    final alunos = <MigracaoAlunoLinha>[];
    for (var i = start; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((c) => c.toString().trim().isEmpty)) continue;

      String? nome;
      String? email;
      String? telefone;
      String? objetivo;

      if (hasRecognizedHeader) {
        nome = _cell(row, nomeIdx);
        email = _cell(row, emailIdx);
        telefone = _cell(row, telIdx);
        objetivo = _cell(row, objIdx);
      } else {
        final parts =
            row
                .map((c) => c.toString().trim())
                .where((p) => p.isNotEmpty)
                .toList();
        if (parts.isEmpty) continue;
        nome = parts.first;
        for (final part in parts.skip(1)) {
          if (email == null && part.contains('@')) {
            email = part;
          } else if (telefone == null && _looksLikePhone(part)) {
            telefone = part;
          } else {
            objetivo ??= part;
          }
        }
      }

      if ((nome == null || nome.isEmpty) && (email == null || email.isEmpty)) {
        continue;
      }

      alunos.add(
        MigracaoAlunoLinha(
          nome: (nome == null || nome.isEmpty) ? 'Aluno importado' : nome,
          email: email,
          telefone: telefone,
          objetivo: objetivo,
        ),
      );
    }

    return alunos.isEmpty ? null : alunos;
  }

  static int? _indexFor(List<String> header, List<String> keys) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i];
      if (keys.any((k) => h == k || h.contains(k))) return i;
    }
    return null;
  }

  static String? _cell(List<dynamic> row, int? index) {
    if (index == null || index >= row.length) return null;
    final v = row[index].toString().trim();
    return v.isEmpty ? null : v;
  }

  static String _norm(String value) =>
      value
          .toLowerCase()
          .replaceAll('\ufeff', '')
          .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  static bool _looksLikePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 13;
  }
}
