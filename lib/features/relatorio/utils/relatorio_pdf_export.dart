import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/focux_pdf_kit.dart';
import '../../../core/utils/pt_br_display.dart';
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

/// Monta o PDF de aderência (testável sem abrir a impressão).
Future<Uint8List> buildRelatorioPdf({
  required FocuxPdfAssets assets,
  required String alunoNome,
  required String periodoLabel,
  required AderenciaData dados,
  ComparativoPeriodo? comparativo,
  FocuxPdfBrand? brand,
  DateTime? agora,
}) {
  final marca = brand ?? FocuxPdfBrand.focux();
  final checkIns = comparativo?.checkInsAtual;
  final doc = pw.Document(
    title: 'Relatório de aderência · $alunoNome',
    author: marca.nome,
    theme: focuxPdfTheme(assets),
  );
  doc.addPage(
    focuxPdfPage(
      assets: assets,
      brand: marca,
      titulo: 'Relatório de aderência',
      subtitulo: alunoNome,
      linhasMeta: ['Período: $periodoLabel'],
      geradoLabel: focuxPdfGeradoLabel(agora ?? DateTime.now()),
      build: (_) => [
        focuxPdfKpiRow([
          (
            titulo: 'Aderência',
            valor: '${formatBrDecimal(dados.taxaAderenciaPercent)}%',
            legenda: null,
          ),
          (
            titulo: 'Treinos feitos',
            valor: '${dados.treinosConcluidos} de ${dados.treinosTotal}',
            legenda: null,
          ),
          (
            titulo: 'Check-ins',
            valor: checkIns == null ? '—' : '$checkIns',
            legenda: null,
          ),
        ]),
        pw.SizedBox(height: 18),
        if (comparativo != null) ...[
          ...focuxPdfSection('Aderência: atual x período anterior', [
            focuxPdfBarChart(
              [
                (label: 'Período atual', valor: comparativo.aderenciaAtual),
                (label: 'Anterior', valor: comparativo.aderenciaAnterior),
              ],
              formatar: (v) => '${formatBrDecimal(v)}%',
            ),
          ]),
          ...focuxPdfSection('Comparativo', [
            focuxPdfTable(
              headers: const ['', 'Atual', 'Anterior', 'Variação'],
              rows: [
                [
                  'Aderência',
                  '${formatBrDecimal(comparativo.aderenciaAtual)}%',
                  '${formatBrDecimal(comparativo.aderenciaAnterior)}%',
                  _variacao(comparativo.aderenciaAtual - comparativo.aderenciaAnterior, '%'),
                ],
                [
                  'Check-ins',
                  '${comparativo.checkInsAtual}',
                  '${comparativo.checkInsAnterior}',
                  _variacaoInteira(
                    comparativo.checkInsAtual - comparativo.checkInsAnterior,
                  ),
                ],
              ],
              cellAlignments: const {
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
          ]),
        ],
      ],
    ),
  );
  return doc.save();
}

String _variacao(double delta, String sufixo) {
  final sinal = delta > 0 ? '+' : '';
  return '$sinal${formatBrDecimal(delta)}$sufixo';
}

String _variacaoInteira(int delta) => delta > 0 ? '+$delta' : '$delta';

Future<void> exportRelatorioPdf({
  required String alunoNome,
  required String periodoLabel,
  required AderenciaData dados,
  ComparativoPeriodo? comparativo,
  String? appDisplayName,
  bool ocultarMarcaFocux = false,
}) async {
  final assets = await FocuxPdfAssets.load();
  final bytes = await buildRelatorioPdf(
    assets: assets,
    alunoNome: alunoNome,
    periodoLabel: periodoLabel,
    dados: dados,
    comparativo: comparativo,
    brand: FocuxPdfBrand.from(
      nomeMarca: appDisplayName,
      ocultarFocux: ocultarMarcaFocux,
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}
