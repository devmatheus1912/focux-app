import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'anamnese_display.dart';

class AnamnesePdfSnapshot {
  const AnamnesePdfSnapshot({
    required this.objetivo,
    required this.nivelAtividade,
    required this.lesoes,
    required this.medicamentos,
    required this.observacoes,
    required this.historicoMedico,
    required this.cirurgias,
    required this.doresCronicas,
    required this.objetivoDetalhado,
    required this.disponibilidadeSemanal,
    required this.preferenciasTreino,
    required this.restricoesAlimentares,
  });

  final String objetivo;
  final String? nivelAtividade;
  final String lesoes;
  final String medicamentos;
  final String observacoes;
  final String historicoMedico;
  final String cirurgias;
  final String doresCronicas;
  final String objetivoDetalhado;
  final int disponibilidadeSemanal;
  final String preferenciasTreino;
  final String restricoesAlimentares;
}

Future<void> exportAnamnesePdf(AnamnesePdfSnapshot s) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build:
          (ctx) => [
            pw.Text(
              'Ficha de Anamnese',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
            _secao('Básico'),
            _campo('Objetivo', s.objetivo),
            _campo(
              'Nível de atividade',
              s.nivelAtividade == null
                  ? '—'
                  : anamneseNivelLabel(s.nivelAtividade),
            ),
            _campo('Lesões / Limitações', s.lesoes),
            _campo('Medicamentos', s.medicamentos),
            _campo('Observações', s.observacoes),
            pw.SizedBox(height: 12),
            _secao('Saúde'),
            _campo('Histórico médico', s.historicoMedico),
            _campo('Cirurgias', s.cirurgias),
            _campo('Dores crônicas', s.doresCronicas),
            pw.SizedBox(height: 12),
            _secao('Treino & Nutrição'),
            _campo('Objetivo detalhado', s.objetivoDetalhado),
            _campo(
              'Disponibilidade semanal',
              anamneseDisponibilidadeLabel(s.disponibilidadeSemanal),
            ),
            _campo('Preferências de treino', s.preferenciasTreino),
            _campo('Restrições alimentares', s.restricoesAlimentares),
          ],
    ),
  );
  await Printing.layoutPdf(onLayout: (_) async => doc.save());
}

pw.Widget _secao(String titulo) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 4),
  child: pw.Text(
    titulo,
    style: pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.blueGrey700,
    ),
  ),
);

pw.Widget _campo(String label, String value) {
  if (value.trim().isEmpty) return pw.SizedBox();
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    ),
  );
}
