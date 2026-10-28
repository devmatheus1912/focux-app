import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_link_row.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('FxLinkRow: linha toda toca, tem seta e alvo de 56', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxLinkRow(
            label: 'Ver todos os 5 sinais',
            detalhe: '5',
            onTap: () => toques++,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(
      tester.getSize(find.byType(FxLinkRow)).height,
      greaterThanOrEqualTo(56),
    );
    await tester.tap(find.text('Ver todos os 5 sinais'));
    expect(toques, 1);
  });

  testWidgets('FxTonalButton danger usa a cor de erro e continua tonal', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(colorScheme: const ColorScheme.light(error: Colors.red)),
        home: Scaffold(
          body: FxTonalButton(label: 'Excluir', danger: true, onPressed: () {}),
        ),
      ),
    );
    final texto = tester.widget<Text>(find.text('Excluir'));
    expect(texto.style?.color, isNot(Colors.black));
    expect(find.byType(TextButton), findsNothing);
  });
}
