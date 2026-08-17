import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/relatorio_repository.dart';

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

Future<void> exportRelatorioPdf({
  required String alunoNome,
  required String periodoLabel,
  required AderenciaData dados,
  ComparativoPeriodo? comparativo,
}) async {
  final doc = pw.Document();
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório de Aderência — $alunoNome',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Período Analisado: $periodoLabel',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfCard(
                  'Taxa de Aderência',
                  '${dados.taxaAderenciaPercent.toStringAsFixed(1)}%',
                ),
                _pdfCard(
                  'Treinos Concluídos',
                  '${dados.treinosConcluidos} / ${dados.treinosTotal}',
                ),
                _pdfCard('Dias Analisados', '${dados.diasAnalisados}'),
              ],
            ),
            pw.SizedBox(height: 24),
            if (comparativo != null) ...[
              pw.Text(
                'Comparativo com Período Anterior',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Aderência Atual: ${comparativo.aderenciaAtual.toStringAsFixed(1)}% (${comparativo.checkInsAtual} check-ins)',
              ),
              pw.Text(
                'Aderência Anterior: ${comparativo.aderenciaAnterior.toStringAsFixed(1)}% (${comparativo.checkInsAnterior} check-ins)',
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Evolução: ${(comparativo.aderenciaAtual - comparativo.aderenciaAnterior).toStringAsFixed(1)}%',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color:
                      comparativo.aderenciaAtual >= comparativo.aderenciaAnterior
                          ? PdfColors.green
                          : PdfColors.red,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

pw.Widget _pdfCard(String title, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
      ],
    ),
  );
}
