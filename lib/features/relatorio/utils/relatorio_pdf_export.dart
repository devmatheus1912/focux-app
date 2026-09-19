import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/relatorio_repository.dart';

/// Brand tokens mirrored as [PdfColor] (EagleTokens navy / azul petróleo).
const PdfColor _pdfNavy = PdfColor.fromInt(0xFF0B1524);
const PdfColor _pdfBrand = PdfColor.fromInt(0xFF0B4F5C);
const PdfColor _pdfBrandDeep = PdfColor.fromInt(0xFF083D47);
const PdfColor _pdfInk = PdfColor.fromInt(0xFF1A1A2E);
const PdfColor _pdfMute = PdfColor.fromInt(0xFF6B7280);
const PdfColor _pdfLine = PdfColor.fromInt(0xFFE5E7EB);
const PdfColor _pdfPaper = PdfColor.fromInt(0xFFF4F6F8);
const PdfColor _pdfGood = PdfColor.fromInt(0xFF1B8C54);
const PdfColor _pdfBad = PdfColor.fromInt(0xFFC73A3A);

String relatorioPeriodoLabelPdf({
  required int dias,
  DateTimeRangePdf? rangeCustom,
}) {
  if (rangeCustom != null) {
    final s = rangeCustom.start;
    final e = rangeCustom.end;
    return '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}/${s.year} – ${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}/${e.year}';
  }
  return '$dias dias';
}

class DateTimeRangePdf {
  const DateTimeRangePdf({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// Carimbo do PDF: marca própria quando white-label ativo; senão FOCUX.
String relatorioPdfBrandLabel({
  String? appDisplayName,
  bool ocultarMarcaFocux = false,
}) {
  if (ocultarMarcaFocux) {
    final n = (appDisplayName ?? '').trim();
    if (n.isNotEmpty) return n;
  }
  return 'FOCUX';
}

Future<void> exportRelatorioPdf({
  required String alunoNome,
  required String periodoLabel,
  required AderenciaData dados,
  ComparativoPeriodo? comparativo,
  String? appDisplayName,
  bool ocultarMarcaFocux = false,
}) async {
  final gerado = DateTime.now();
  final geradoLabel =
      '${gerado.day.toString().padLeft(2, '0')}/'
      '${gerado.month.toString().padLeft(2, '0')}/'
      '${gerado.year} '
      '${gerado.hour.toString().padLeft(2, '0')}:'
      '${gerado.minute.toString().padLeft(2, '0')}';
  final checkIns = comparativo?.checkInsAtual;
  final brand = relatorioPdfBrandLabel(
    appDisplayName: appDisplayName,
    ocultarMarcaFocux: ocultarMarcaFocux,
  );
  final branded = brand != 'FOCUX';

  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _pdfHeader(brand: brand, branded: branded),
            pw.SizedBox(height: 20),
            pw.Text(
              'Relatório de aderência',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _pdfNavy,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              alunoNome,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: _pdfBrandDeep,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Período: $periodoLabel',
              style: const pw.TextStyle(fontSize: 11, color: _pdfMute),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _pdfKpiCard(
                    'Taxa de aderência',
                    '${dados.taxaAderenciaPercent.toStringAsFixed(1)}%',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    'Dias',
                    '${dados.treinosConcluidos} / ${dados.treinosTotal}',
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _pdfKpiCard(
                    'Check-ins',
                    checkIns == null ? '—' : '$checkIns',
                  ),
                ),
              ],
            ),
            if (comparativo != null) ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Comparativo com o período anterior',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _pdfNavy,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: _pdfPaper,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: _pdfLine),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Atual: ${comparativo.aderenciaAtual.toStringAsFixed(1)}% · ${comparativo.checkInsAtual} check-ins',
                      style: const pw.TextStyle(fontSize: 11, color: _pdfInk),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Anterior: ${comparativo.aderenciaAnterior.toStringAsFixed(1)}% · ${comparativo.checkInsAnterior} check-ins',
                      style: const pw.TextStyle(fontSize: 11, color: _pdfInk),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Evolução: ${(comparativo.aderenciaAtual - comparativo.aderenciaAnterior).toStringAsFixed(1)}%',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color:
                            comparativo.aderenciaAtual >=
                                    comparativo.aderenciaAnterior
                                ? _pdfGood
                                : _pdfBad,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            pw.Spacer(),
            _pdfFooter(geradoLabel, brand: brand, branded: branded),
          ],
        );
      },
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

pw.Widget _pdfHeader({required String brand, required bool branded}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: const pw.BoxDecoration(
      color: _pdfNavy,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          brand.toUpperCase(),
          style: pw.TextStyle(
            fontSize: branded ? 12 : 14,
            fontWeight: pw.FontWeight.bold,
            color: _pdfBrand,
            letterSpacing: branded ? 0.6 : 1.2,
          ),
        ),
        pw.Text(
          branded ? 'Relatório' : 'Personal',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.white),
        ),
      ],
    ),
  );
}

pw.Widget _pdfKpiCard(String title, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _pdfPaper,
      border: pw.Border.all(color: _pdfLine),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 28,
          height: 3,
          decoration: const pw.BoxDecoration(
            color: _pdfBrand,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _pdfNavy,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 9, color: _pdfMute),
        ),
      ],
    ),
  );
}

pw.Widget _pdfFooter(
  String geradoLabel, {
  required String brand,
  required bool branded,
}) {
  return pw.Column(
    children: [
      pw.Container(height: 1, color: _pdfLine),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado em $geradoLabel',
            style: const pw.TextStyle(fontSize: 9, color: _pdfMute),
          ),
          pw.Text(
            branded ? brand : 'focux.app',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _pdfBrandDeep,
            ),
          ),
        ],
      ),
    ],
  );
}
