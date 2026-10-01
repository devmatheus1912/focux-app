import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';

import '../models/migracao_aluno_linha.dart';
import 'migracao_linha_classifier.dart';

/// Índice de cada campo nas colunas da planilha (`null` = não importar).
class MigracaoColunas {
  const MigracaoColunas({this.nome, this.email, this.telefone, this.objetivo});

  final int? nome;
  final int? email;
  final int? telefone;
  final int? objetivo;

  bool get temIdentificacao => nome != null || email != null || telefone != null;
}

/// Resultado ao importar CSV/XLSX/TXT para a Migração Focux.
class MigracaoFileParseResult {
  const MigracaoFileParseResult({
    this.directAlunos,
    this.textForIa,
    required this.sourceLabel,
    this.colunas,
    this.headers = const [],
    this.rows = const [],
    this.ignorados = 0,
  });

  /// Planilha estruturada — vai direto para preview sem IA.
  final List<MigracaoAlunoLinha>? directAlunos;

  /// Texto para colar/processar com IA.
  final String? textForIa;

  final String sourceLabel;

  /// Mapeamento reconhecido no cabeçalho (só planilha com cabeçalho).
  final MigracaoColunas? colunas;
  final List<String> headers;

  /// Linhas de dados (sem o cabeçalho), para remapear colunas.
  final List<List<String>> rows;

  /// Linhas descartadas por não parecerem alunos.
  final int ignorados;

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

  /// Refaz as linhas com o mapeamento escolhido pelo personal.
  static MigracaoFileParseResult reaplicarColunas(
    MigracaoFileParseResult r,
    MigracaoColunas colunas,
  ) {
    final (alunos, ignorados) = _linhasComColunas(r.rows, colunas);
    return MigracaoFileParseResult(
      directAlunos: alunos,
      sourceLabel: r.sourceLabel,
      colunas: colunas,
      headers: r.headers,
      rows: r.rows,
      ignorados: ignorados,
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

    return _estruturado(_asStrings(rows), filename) ??
        MigracaoFileParseResult(textForIa: text.trim(), sourceLabel: filename);
  }

  static MigracaoFileParseResult _parseXlsx(Uint8List bytes, String filename) {
    try {
      final book = Excel.decodeBytes(bytes);
      if (book.tables.isEmpty) {
        return MigracaoFileParseResult(textForIa: '', sourceLabel: filename);
      }
      final sheet = book.tables.values.first;
      final rows = <List<String>>[
        for (final row in sheet.rows)
          [for (final cell in row) cell?.value?.toString() ?? ''],
      ];
      final estruturado = _estruturado(rows, filename);
      if (estruturado != null) return estruturado;

      final buffer = StringBuffer();
      for (final row in rows) {
        final line = row
            .map((v) => v.trim())
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

  static List<List<String>> _asStrings(List<List<dynamic>> rows) => [
    for (final row in rows) [for (final c in row) c.toString()],
  ];

  static MigracaoFileParseResult? _estruturado(
    List<List<String>> rows,
    String filename,
  ) {
    final semVazias =
        rows.where((r) => r.any((c) => c.trim().isNotEmpty)).toList();
    if (semVazias.isEmpty) return null;

    final header = semVazias.first;
    final colunas = colunasDoCabecalho(header);
    if (colunas.temIdentificacao && semVazias.length > 1) {
      final dados = semVazias.sublist(1);
      final (alunos, ignorados) = _linhasComColunas(dados, colunas);
      if (alunos.isEmpty) return null;
      return MigracaoFileParseResult(
        directAlunos: alunos,
        sourceLabel: filename,
        colunas: colunas,
        headers: [for (final h in header) h.trim()],
        rows: dados,
        ignorados: ignorados,
      );
    }

    final (alunos, ignorados) = _linhasSemCabecalho(semVazias);
    if (alunos.isEmpty) return null;
    return MigracaoFileParseResult(
      directAlunos: alunos,
      sourceLabel: filename,
      ignorados: ignorados,
    );
  }

  static const _sinonimos = {
    'nome': {'nome', 'name', 'aluno', 'cliente'},
    'email': {'email', 'mail'},
    'telefone': {'telefone', 'celular', 'whatsapp', 'whats', 'phone', 'tel', 'fone', 'contato'},
    'objetivo': {'objetivo', 'objetivos', 'goal', 'meta'},
  };

  static MigracaoColunas colunasDoCabecalho(List<String> header) {
    int? achar(String campo) {
      for (var i = 0; i < header.length; i++) {
        final norm = _norm(header[i]);
        if (campo == 'email' && norm.contains('e mail')) return i;
        final tokens = norm.split(' ');
        if (tokens.any(_sinonimos[campo]!.contains)) return i;
      }
      return null;
    }

    return MigracaoColunas(
      nome: achar('nome'),
      email: achar('email'),
      telefone: achar('telefone'),
      objetivo: achar('objetivo'),
    );
  }

  static (List<MigracaoAlunoLinha>, int) _linhasComColunas(
    List<List<String>> rows,
    MigracaoColunas colunas,
  ) {
    final alunos = <MigracaoAlunoLinha>[];
    var ignorados = 0;
    for (final row in rows) {
      final linha = _linha(
        nome: _cell(row, colunas.nome),
        email: _cell(row, colunas.email),
        telefone: _cell(row, colunas.telefone),
        objetivo: _cell(row, colunas.objetivo),
      );
      if (linha == null) {
        ignorados++;
      } else {
        alunos.add(linha);
      }
    }
    return (alunos, ignorados);
  }

  static (List<MigracaoAlunoLinha>, int) _linhasSemCabecalho(
    List<List<String>> rows,
  ) {
    final alunos = <MigracaoAlunoLinha>[];
    var ignorados = 0;
    for (final row in rows) {
      final parts =
          row.map((c) => c.trim()).where((p) => p.isNotEmpty).toList();
      String? email;
      String? telefone;
      String? objetivo;
      final nomeParts = <String>[];
      for (final part in parts) {
        if (email == null && migracaoEmailValido(part)) {
          email = part;
        } else if (telefone == null && migracaoTelefoneValido(part)) {
          telefone = part;
        } else if (nomeParts.isEmpty) {
          nomeParts.add(part);
        } else {
          objetivo ??= part;
        }
      }
      final linha = _linha(
        nome: nomeParts.isEmpty ? null : nomeParts.first,
        email: email,
        telefone: telefone,
        objetivo: objetivo,
      );
      if (linha == null) {
        ignorados++;
      } else {
        alunos.add(linha);
      }
    }
    return (alunos, ignorados);
  }

  static MigracaoAlunoLinha? _linha({
    String? nome,
    String? email,
    String? telefone,
    String? objetivo,
  }) {
    final status = migracaoClassificar(nome, email, telefone);
    if (status == MigracaoLinhaStatus.ignorado) return null;
    final nomeFinal = (nome == null || nome.isEmpty) ? _nomeDoEmail(email) : nome;
    return MigracaoAlunoLinha(
      nome: nomeFinal,
      email: email,
      telefone: telefone,
      objetivo: objetivo,
      status: status,
    );
  }

  static String _nomeDoEmail(String? email) {
    if (email == null || !email.contains('@')) return 'Aluno sem nome';
    final local =
        email.split('@').first.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
    if (local.isEmpty) return 'Aluno sem nome';
    return local[0].toUpperCase() + local.substring(1);
  }

  static String? _cell(List<String> row, int? index) {
    if (index == null || index >= row.length) return null;
    final v = row[index].trim();
    return v.isEmpty ? null : v;
  }

  static String _norm(String value) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    final buf = StringBuffer();
    for (final ch in value.toLowerCase().replaceAll('\ufeff', '').split('')) {
      final i = de.indexOf(ch);
      buf.write(i >= 0 ? para[i] : ch);
    }
    return buf
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
