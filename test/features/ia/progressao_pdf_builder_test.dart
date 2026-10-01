import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/pdf/focux_pdf_kit.dart';
import 'package:focux_app/features/ia/models/ia_progressao_carga_result.dart';
import 'package:focux_app/features/ia/utils/progressao_pdf_builder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera PDF com fontes e logo dos assets', () async {
    final result = IaProgressaoCargaResult.fromApi({
      'resposta': 'resumo',
      'intro': 'Progressão leve.',
      'footer': 'Respeite a técnica.',
      'exercicios': [
        for (var i = 0; i < 40; i++)
          {
            'exercicio': 'Exercício $i',
            'cargaAtual': '60 kg · 3×10',
            'cargaSugerida': '62,5 kg · 3×10',
            'justificativa': 'Fez 60 kg×10 nas três últimas sessões.',
            'deltaKg': 2.5,
          },
      ],
    });

    final assets = await FocuxPdfAssets.load();
    final bytes = await buildProgressaoPdf(
      result: result,
      alunoNome: 'Ana',
      personalNome: 'Personal Teste',
      assets: assets,
      agora: DateTime(2026, 9, 30, 10),
    );

    expect(assets.logo, isNotNull);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(10000));
  });
}
