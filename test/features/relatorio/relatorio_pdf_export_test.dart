import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_kit.dart';
import 'package:focux_app/features/relatorio/data/relatorio_repository.dart';
import 'package:focux_app/features/relatorio/utils/relatorio_pdf_export.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// PNG 1x1 transparente
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

AderenciaData _dados() => AderenciaData(
  diasAnalisados: 30,
  treinosConcluidos: 9,
  treinosTotal: 12,
  taxaAderenciaPercent: 75,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocuxPdfBrand.doPersonal', () {
    test('com nome vira marca do personal, com cor, slogan e logo', () {
      final marca = FocuxPdfBrand.doPersonal(
        nome: ' Studio Força ',
        corHex: '#1A2332',
        slogan: ' Treino com método ',
        logo: pw.MemoryImage(_png),
        ocultarFocux: true,
      );
      expect(marca.nome, 'Studio Força');
      expect(marca.whiteLabel, isTrue);
      expect(marca.slogan, 'Treino com método');
      expect(marca.logo, isNotNull);
      expect(marca.cor, const PdfColor.fromInt(0xFF1A2332));
      expect(marca.rodape, 'Studio Força');
    });

    test('sem ocultar a Focux, o selo e o rodapé da Focux continuam', () {
      final marca = FocuxPdfBrand.doPersonal(
        nome: 'Studio',
        ocultarFocux: false,
      );
      expect(marca.whiteLabel, isFalse);
      expect(marca.rodape, 'focux.app');
    });

    test('sem nome volta para a Focux inteira', () {
      final marca = FocuxPdfBrand.doPersonal(nome: '  ', corHex: '#112233');
      expect(marca.nome, 'Focux');
      expect(marca.whiteLabel, isFalse);
      expect(marca.slogan, isNull);
    });

    test('cor inválida e slogan vazio caem no padrão', () {
      final marca = FocuxPdfBrand.doPersonal(
        nome: 'Studio',
        corHex: 'roxo',
        slogan: '   ',
      );
      expect(marca.cor, FocuxPdfColors.brand);
      expect(marca.slogan, isNull);
    });
  });

  group('pdfColorDeHex', () {
    test('lê com e sem #, em maiúscula ou minúscula', () {
      expect(pdfColorDeHex('#0b4f5c'), const PdfColor.fromInt(0xFF0B4F5C));
      expect(pdfColorDeHex('C9A962'), const PdfColor.fromInt(0xFFC9A962));
    });

    test('rejeita o que não é cor', () {
      for (final ruim in [null, '', '#12', '#GGGGGG', '#12345678', 'azul']) {
        expect(pdfColorDeHex(ruim), isNull, reason: '$ruim');
      }
    });
  });

  group('PDF de aderência', () {
    Future<List<int>> gerar(FocuxPdfBrand? marca) async => buildRelatorioPdf(
      assets: await FocuxPdfAssets.load(),
      alunoNome: 'Ana Souza',
      periodoLabel: '30 dias',
      dados: _dados(),
      comparativo: ComparativoPeriodo(
        aderenciaAtual: 75,
        aderenciaAnterior: 60,
        deltaPercent: 15,
        checkInsAtual: 9,
        checkInsAnterior: 7,
      ),
      brand: marca,
      agora: DateTime(2026, 10, 1, 9),
    );

    test('sai com a marca própria: cor, slogan e logo', () async {
      final bytes = await gerar(
        FocuxPdfBrand.doPersonal(
          nome: 'Studio Força',
          corHex: '#1A2332',
          slogan: 'Treino com método',
          logo: pw.MemoryImage(_png),
          ocultarFocux: true,
        ),
      );
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));
    });

    test('sem marca segue o PDF Focux', () async {
      final bytes = await gerar(null);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(10000));
    });

    test('a marca muda o documento (não é o mesmo PDF)', () async {
      final focux = await gerar(null);
      final marca = await gerar(
        FocuxPdfBrand.doPersonal(
          nome: 'Studio Força',
          corHex: '#C9A962',
          slogan: 'Treino com método',
          ocultarFocux: true,
        ),
      );
      expect(marca.length == focux.length && _igual(marca, focux), isFalse);
    });
  });
}

bool _igual(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
