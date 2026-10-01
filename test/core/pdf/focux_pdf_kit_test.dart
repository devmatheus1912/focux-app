import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_kit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

int _paginas(List<int> bytes) =>
    RegExp(r'/Type\s*/Page[^s]').allMatches(latin1.decode(bytes)).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega fontes e logo dos assets', () async {
    final assets = await FocuxPdfAssets.load();
    expect(assets.logo, isNotNull);
  });

  test('tabela longa quebra em várias páginas sem estourar', () async {
    final assets = await FocuxPdfAssets.load();
    final doc = pw.Document(theme: focuxPdfTheme(assets));
    doc.addPage(
      focuxPdfPage(
        assets: assets,
        brand: FocuxPdfBrand.focux(),
        titulo: 'Teste',
        geradoLabel: '01/10/2026 10:00',
        disclaimer: 'Rodapé',
        build: (_) => [
          ...focuxPdfSection('Linhas', [
            focuxPdfTable(
              headers: const ['Dia', 'Status'],
              rows: [
                for (var i = 0; i < 200; i++) ['Dia $i', 'Concluído'],
              ],
            ),
          ]),
          ...focuxPdfSection(
            'Campos',
            focuxPdfFieldPairs([
              for (var i = 0; i < 80; i++) ('Campo $i', 'Valor $i'),
            ]),
          ),
        ],
      ),
    );
    final bytes = await doc.save();
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(_paginas(bytes), greaterThanOrEqualTo(2));
  });

  test('marca própria troca o nome do cabeçalho', () {
    const brand = FocuxPdfBrand(
      nome: 'Studio Força',
      cor: PdfColor.fromInt(0xFF7A1F5C),
      whiteLabel: true,
    );
    expect(brand.cabecalho, 'STUDIO FORÇA');
    expect(FocuxPdfBrand.focux().cabecalho, 'FOCUX');
    expect(FocuxPdfBrand.focux().rodape, 'focux.app');
    expect(brand.rodape, 'Studio Força');
  });

  test('pares de campo pulam valores vazios', () {
    expect(focuxPdfParesPreenchidos([('A', 'x'), ('B', ' '), ('C', '—')]), [
      ('A', 'x'),
    ]);
  });
}
