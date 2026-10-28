import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_set_dots.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget app(List<FxSetDot> series) => MaterialApp(
    home: Scaffold(
      body: FxSetDots(series: series, accent: Colors.teal),
    ),
  );

  testWidgets('feitas mostram o que foi registrado; a próxima e as demais, o número',
      (tester) async {
    await tester.pumpWidget(
      app(const [
        FxSetDot(numero: 1, feita: true, detalhe: '40×10'),
        FxSetDot(numero: 2, feita: false),
        FxSetDot(numero: 3, feita: false),
      ]),
    );
    expect(find.text('40×10'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('o leitor de tela diz o estado de cada série', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(const [
        FxSetDot(numero: 1, feita: true, detalhe: '40×10'),
        FxSetDot(numero: 2, feita: false),
        FxSetDot(numero: 3, feita: false),
      ]),
    );
    expect(find.bySemanticsLabel('Série 1, feita, 40×10'), findsOneWidget);
    expect(find.bySemanticsLabel('Série 2, próxima'), findsOneWidget);
    expect(find.bySemanticsLabel('Série 3, pendente'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('aquecimento aparece como A', (tester) async {
    await tester.pumpWidget(
      app(const [FxSetDot(numero: 1, feita: false, aquecimento: true)]),
    );
    expect(find.text('A'), findsOneWidget);
  });
}
