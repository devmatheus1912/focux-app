import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/widgets/focux_official_logo.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../models/ia_progressao_carga_result.dart';
import 'progressao_copy.dart';

class ProgressaoPdfAssets {
  const ProgressaoPdfAssets({
    required this.regular,
    required this.bold,
    this.logo,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.MemoryImage? logo;

  static Future<ProgressaoPdfAssets> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final regular = await b.load('assets/google_fonts/Inter-Regular.ttf');
    final bold = await b.load('assets/google_fonts/Inter-Bold.ttf');
    pw.MemoryImage? logo;
    try {
      final bytes = await b.load(FocuxOfficialLogo.assetLight);
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }
    return ProgressaoPdfAssets(
      regular: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
      logo: logo,
    );
  }
}

const _ink = PdfColor.fromInt(0xFF1A1A1A);
const _muted = PdfColor.fromInt(0xFF6B6B6B);
const _line = PdfColor.fromInt(0xFFE3E3E3);
const _accent = PdfColor.fromInt(0xFF0B4F5C);
const _accentSoft = PdfColor.fromInt(0xFFEBF4F6);

/// Monta o PDF a partir do mesmo resultado exibido na tela.
Future<Uint8List> buildProgressaoPdf({
  required IaProgressaoCargaResult result,
  required String alunoNome,
  required ProgressaoPdfAssets assets,
  String? personalNome,
  DateTime? agora,
}) {
  final geradoEm = result.geradoEm ?? agora ?? DateTime.now();
  final doc = pw.Document(
    title: 'Progressão de carga · $alunoNome',
    author: personalNome ?? 'Focux',
    theme: pw.ThemeData.withFont(base: assets.regular, bold: assets.bold),
  );
  final body = pw.TextStyle(fontSize: 10, color: _ink, lineSpacing: 2);
  final muted = pw.TextStyle(fontSize: 9, color: _muted, lineSpacing: 2);
  final bold = pw.TextStyle(fontSize: 10, color: _ink, fontWeight: pw.FontWeight.bold);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 40),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text('Progressão de carga · $alunoNome', style: muted),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Focux · página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: muted,
        ),
      ),
      build: (ctx) => [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Progressão de carga',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Aluno: $alunoNome', style: body),
                  if (personalNome != null && personalNome.trim().isNotEmpty)
                    pw.Text('Personal: ${personalNome.trim()}', style: body),
                  pw.Text(progressaoGeradoLabel(geradoEm), style: muted),
                ],
              ),
            ),
            if (assets.logo != null)
              pw.SizedBox(height: 32, child: pw.Image(assets.logo!)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 2, color: _accent),
        pw.SizedBox(height: 14),
        if (result.intro != null) ...[
          pw.Text(result.intro!, style: body),
          pw.SizedBox(height: 14),
        ],
        pw.TableHelper.fromTextArray(
          headers: const ['Exercício', 'Atual', 'Sugerido', 'Δ'],
          data: [
            for (final e in result.exercises)
              [e.exercicio, e.cargaAtual, e.cargaSugerida, e.deltaLabel ?? '—'],
          ],
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: _accent),
          cellStyle: body,
          cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          oddRowDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF7F7F7)),
          border: const pw.TableBorder(
            horizontalInside: pw.BorderSide(color: _line, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2.2),
            2: pw.FlexColumnWidth(2.2),
            3: pw.FlexColumnWidth(1),
          },
          cellAlignments: const {3: pw.Alignment.centerRight},
        ),
        if (result.exercises.any((e) => e.justificativa.isNotEmpty)) ...[
          pw.SizedBox(height: 18),
          pw.Text('Por que cada ajuste', style: bold),
          pw.SizedBox(height: 6),
          for (final e in result.exercises.where((e) => e.justificativa.isNotEmpty))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: '${e.exercicio}: ', style: bold),
                    pw.TextSpan(text: e.justificativa, style: body),
                  ],
                ),
              ),
            ),
        ],
        if (result.footer != null) ...[
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(
              color: _accentSoft,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(result.footer!, style: body),
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Text(iaPdfDisclaimer(personalNome), style: muted),
      ],
    ),
  );
  return doc.save();
}
