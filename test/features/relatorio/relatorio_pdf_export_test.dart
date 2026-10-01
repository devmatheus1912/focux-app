import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_kit.dart';
import 'package:focux_app/features/relatorio/data/relatorio_repository.dart';
import 'package:focux_app/features/relatorio/utils/relatorio_pdf_export.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF de aderência sai com comparativo e marca própria', () async {
    final assets = await FocuxPdfAssets.load();
    final bytes = await buildRelatorioPdf(
      assets: assets,
      alunoNome: 'Ana Souza',
      periodoLabel: '30 dias',
      dados: AderenciaData(
        diasAnalisados: 30,
        treinosConcluidos: 9,
        treinosTotal: 12,
        taxaAderenciaPercent: 75,
      ),
      comparativo: ComparativoPeriodo(
        aderenciaAtual: 75,
        aderenciaAnterior: 60,
        deltaPercent: 15,
        checkInsAtual: 9,
        checkInsAnterior: 7,
      ),
      brand: FocuxPdfBrand.from(nomeMarca: 'Studio Força', ocultarFocux: true),
      agora: DateTime(2026, 10, 1, 9),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });

  test('sem nome de marca volta para Focux', () {
    expect(FocuxPdfBrand.from(nomeMarca: '  ', ocultarFocux: true).whiteLabel, isFalse);
    expect(FocuxPdfBrand.from(nomeMarca: 'Studio', ocultarFocux: false).whiteLabel, isFalse);
  });
}
