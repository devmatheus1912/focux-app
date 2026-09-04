import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/anamnese_repository.dart';
import 'anamnese_display.dart';

class AnamnesePdfSnapshot {
  const AnamnesePdfSnapshot({required this.anamnese});

  final Anamnese anamnese;
}

Future<void> exportAnamnesePdf(AnamnesePdfSnapshot s) async {
  final a = s.anamnese;
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
              'Status: ${anamneseStatusLabel(a.status)} · '
              'Gerado em: ${DateTime.now().toString().substring(0, 16)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            if (a.alertas.isNotEmpty) ...[
              pw.SizedBox(height: 8),
              _campo('Alertas', a.alertas.join(' · ')),
            ],
            pw.SizedBox(height: 16),
            _secao('PAR-Q+'),
            for (final q in anamneseParqPerguntas)
              _campo(q.label, anamneseBoolLabel(anamneseParqValue(a, q.key))),
            if (a.parqOutraRazaoDetalhe?.trim().isNotEmpty == true)
              _campo('Detalhe (outra razão)', a.parqOutraRazaoDetalhe!),
            pw.SizedBox(height: 12),
            _secao('Saúde'),
            _campo('Histórico médico', a.historicoMedico ?? ''),
            _campo('Cirurgias', a.cirurgias ?? ''),
            _campo('Dores crônicas', a.doresCronicas ?? ''),
            _campo('Lesões / limitações', a.lesoes ?? ''),
            _campo('Medicamentos', a.medicamentos ?? ''),
            _campo('Alergias', a.alergias ?? ''),
            _campo('Gestação / pós-parto', a.gestacaoPosParto ?? ''),
            _campo('Histórico familiar CV', a.historicoFamiliarCv ?? ''),
            _campo('Sintomas CV', a.sintomasCv ?? ''),
            pw.SizedBox(height: 12),
            _secao('Hábitos'),
            _campo('Sono', anamneseSonoHorasLabel(a.sonoHoras)),
            _campo('Qualidade do sono', a.qualidadeSono ?? ''),
            _campo('Nível de estresse', a.nivelEstresse ?? ''),
            _campo('Tabagismo', a.tabagismo ?? ''),
            _campo('Álcool', a.alcool ?? ''),
            _campo('Observações', a.observacoes ?? ''),
            pw.SizedBox(height: 12),
            _secao('Treino e objetivos'),
            _campo('Objetivo', a.objetivo ?? ''),
            _campo('Objetivo detalhado', a.objetivoDetalhado ?? ''),
            _campo(
              'Disponibilidade semanal',
              a.disponibilidadeSemanal == null
                  ? ''
                  : anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
            ),
            _campo('Preferências de treino', a.preferenciasTreino ?? ''),
            _campo('Restrições alimentares', a.restricoesAlimentares ?? ''),
            _campo('Histórico de atividade', a.historicoAtividade ?? ''),
            _campo('Motivo de interrupções', a.motivoInterrupcoes ?? ''),
            _campo('Motivação atual', a.motivacaoAtual ?? ''),
            _campo('Algo mais', a.algoMais ?? ''),
            if (a.nivelAtividade != null) ...[
              pw.SizedBox(height: 8),
              _campo('Nível de atividade (legado)', anamneseNivelLabel(a.nivelAtividade)),
            ],
            if ((a.notasProfissional ?? '').trim().isNotEmpty ||
                (a.atestadoObs ?? '').trim().isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _secao('Revisão do personal'),
              _campo('Notas profissionais', a.notasProfissional ?? ''),
              _campo('Observação de atestado', a.atestadoObs ?? ''),
            ],
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
  if (value.trim().isEmpty || value.trim() == '—') return pw.SizedBox();
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
