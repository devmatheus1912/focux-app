import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/focux_pdf_kit.dart';
import '../data/anamnese_repository.dart';
import 'anamnese_display.dart';

class AnamnesePdfSnapshot {
  const AnamnesePdfSnapshot({required this.anamnese, this.alunoNome});

  final Anamnese anamnese;
  final String? alunoNome;
}

Future<Uint8List> buildAnamnesePdf(
  AnamnesePdfSnapshot s, {
  required FocuxPdfAssets assets,
  DateTime? agora,
}) {
  final a = s.anamnese;
  final nome = s.alunoNome?.trim();
  final doc = pw.Document(title: 'Ficha de anamnese', theme: focuxPdfTheme(assets));
  doc.addPage(
    focuxPdfPage(
      assets: assets,
      brand: FocuxPdfBrand.focux(),
      titulo: 'Ficha de anamnese',
      subtitulo: (nome == null || nome.isEmpty) ? null : nome,
      linhasMeta: ['Status: ${anamneseStatusLabel(a.status)}'],
      geradoLabel: focuxPdfGeradoLabel(agora ?? DateTime.now()),
      build: (_) => [
        if (a.alertas.isNotEmpty) ...[
          focuxPdfCallout('Alertas: ${a.alertas.join(' · ')}', alerta: true),
          pw.SizedBox(height: 14),
        ],
        ...focuxPdfSection(
          'PAR-Q+',
          focuxPdfFieldPairs([
            for (final q in anamneseParqPerguntas)
              (q.label, anamneseBoolLabel(anamneseParqValue(a, q.key))),
            ('Detalhe (outra razão)', a.parqOutraRazaoDetalhe ?? ''),
          ]),
        ),
        ...focuxPdfSection(
          'Saúde',
          focuxPdfFieldPairs([
            ('Histórico médico', a.historicoMedico ?? ''),
            ('Cirurgias', a.cirurgias ?? ''),
            ('Dores crônicas', a.doresCronicas ?? ''),
            ('Lesões / limitações', a.lesoes ?? ''),
            ('Medicamentos', a.medicamentos ?? ''),
            ('Alergias', a.alergias ?? ''),
            ('Gestação / pós-parto', a.gestacaoPosParto ?? ''),
            ('Histórico familiar CV', anamneseBoolLabel(a.historicoFamiliarCv)),
            ('Sintomas CV', a.sintomasCv ?? ''),
          ]),
        ),
        ...focuxPdfSection(
          'Hábitos',
          focuxPdfFieldPairs([
            ('Sono', anamneseSonoHorasLabel(a.sonoHoras)),
            ('Qualidade do sono', a.qualidadeSono ?? ''),
            ('Nível de estresse', a.nivelEstresse ?? ''),
            ('Tabagismo', a.tabagismo ?? ''),
            ('Álcool', a.alcool ?? ''),
            ('Observações', a.observacoes ?? ''),
          ]),
        ),
        ...focuxPdfSection(
          'Treino e objetivos',
          focuxPdfFieldPairs([
            ('Objetivo', a.objetivo ?? ''),
            ('Objetivo detalhado', a.objetivoDetalhado ?? ''),
            (
              'Disponibilidade semanal',
              a.disponibilidadeSemanal == null
                  ? ''
                  : anamneseDisponibilidadeLabel(a.disponibilidadeSemanal!),
            ),
            ('Preferências de treino', a.preferenciasTreino ?? ''),
            ('Restrições alimentares', a.restricoesAlimentares ?? ''),
            ('Histórico de atividade', a.historicoAtividade ?? ''),
            ('Motivo de interrupções', a.motivoInterrupcoes ?? ''),
            ('Motivação atual', a.motivacaoAtual ?? ''),
            ('Algo mais', a.algoMais ?? ''),
            if (a.nivelAtividade != null)
              ('Nível de atividade', anamneseNivelLabel(a.nivelAtividade)),
          ]),
        ),
        if ((a.notasProfissional ?? '').trim().isNotEmpty ||
            (a.atestadoObs ?? '').trim().isNotEmpty)
          ...focuxPdfSection(
            'Revisão do personal',
            focuxPdfFieldPairs([
              ('Notas profissionais', a.notasProfissional ?? ''),
              ('Observação de atestado', a.atestadoObs ?? ''),
            ]),
          ),
      ],
    ),
  );
  return doc.save();
}

Future<void> exportAnamnesePdf(AnamnesePdfSnapshot s) async {
  final bytes = await buildAnamnesePdf(s, assets: await FocuxPdfAssets.load());
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}
