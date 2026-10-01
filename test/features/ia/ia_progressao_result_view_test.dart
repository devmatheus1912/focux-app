import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/models/ia_progressao_carga_result.dart';
import 'package:focux_app/features/ia/widgets/ia_progressao_result_view.dart';

void main() {
  final result = IaProgressaoCargaResult.fromApi({
    'resposta': 'resumo',
    'intro': 'Boa consistência nas últimas semanas.',
    'sugestoesRegistradas': 1,
    'exercicios': [
      {
        'exercicio': 'Supino',
        'cargaAtual': '80 kg · 3×8',
        'cargaSugerida': '82,5 kg · 3×8',
        'justificativa': 'Curta.',
        'deltaKg': 2.5,
      },
    ],
  }, geradoEm: DateTime(2026, 9, 30, 10, 0));

  Future<void> pump(WidgetTester tester, {VoidCallback? onReview}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: IaProgressaoResultView(
              result: result,
              alunoNome: 'Beatriz',
              onExportPdf: () {},
              onReviewSuggestions: onReview,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('card legível em 390px com delta, data e ações', (tester) async {
    await pump(tester, onReview: () {});

    expect(find.text('Supino'), findsOneWidget);
    expect(find.text('80 kg · 3×8'), findsOneWidget);
    expect(find.text('82,5 kg · 3×8'), findsOneWidget);
    expect(find.text('+2,5 kg'), findsOneWidget);
    expect(find.text('Gerado em 30/09/2026 10:00'), findsOneWidget);
    expect(find.text('Revisar e aplicar'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Ver treinos do aluno'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('justificativa curta não mostra "Ler justificativa"', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ler justificativa completa'), findsNothing);
    expect(find.text('Revisar e aplicar'), findsNothing);
  });
}
