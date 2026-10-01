import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/pdf/focux_pdf_kit.dart';
import '../../../core/widgets/ia_safety_disclaimer.dart';
import '../models/ia_progressao_carga_result.dart';
import 'progressao_copy.dart';

/// Monta o PDF a partir do mesmo resultado exibido na tela.
Future<Uint8List> buildProgressaoPdf({
  required IaProgressaoCargaResult result,
  required String alunoNome,
  required FocuxPdfAssets assets,
  String? personalNome,
  DateTime? agora,
}) {
  final geradoEm = result.geradoEm ?? agora ?? DateTime.now();
  final personal = personalNome?.trim() ?? '';
  final doc = pw.Document(
    title: 'Progressão de carga · $alunoNome',
    author: personal.isEmpty ? 'Focux' : personal,
    theme: focuxPdfTheme(assets),
  );
  const body = pw.TextStyle(fontSize: 10, color: FocuxPdfColors.ink, lineSpacing: 2);
  final bold = pw.TextStyle(fontSize: 10, color: FocuxPdfColors.ink, fontWeight: pw.FontWeight.bold);

  doc.addPage(
    focuxPdfPage(
      assets: assets,
      brand: FocuxPdfBrand.focux(),
      titulo: 'Progressão de carga',
      subtitulo: alunoNome,
      linhasMeta: [
        if (personal.isNotEmpty) 'Personal: $personal',
        progressaoGeradoLabel(geradoEm),
      ],
      geradoLabel: focuxPdfGeradoLabel(agora ?? DateTime.now()),
      disclaimer: iaPdfDisclaimer(personalNome),
      build: (ctx) => [
        if (result.intro != null) ...[
          pw.Text(result.intro!, style: body),
          pw.SizedBox(height: 14),
        ],
        focuxPdfTable(
          headers: const ['Exercício', 'Atual', 'Sugerido', 'Δ'],
          rows: [
            for (final e in result.exercises)
              [e.exercicio, e.cargaAtual, e.cargaSugerida, e.deltaLabel ?? '—'],
          ],
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
          ...focuxPdfSection('Por que cada ajuste', [
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
          ]),
        ],
        if (result.footer != null) focuxPdfCallout(result.footer!),
      ],
    ),
  );
  return doc.save();
}
