import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/widgets/fx_motion.dart';
import 'package:focux_app/core/widgets/fx_strip_card.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';

void main() {
  testWidgets('botão tonal não toma a altura da barra inferior', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: Row(
            children: [FxTonalButton(label: 'Voltar', onPressed: () {})],
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(FxTonalButton)).height, 48);
  });

  testWidgets('botão principal sobre o bloco não fica branco no branco', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxStripCard(
            marca: true,
            accent: const Color(0xFF0D9488),
            child: FxLiquidPrimaryButton(label: 'Copiar', onPressed: () {}),
          ),
        ),
      ),
    );
    final cor = tester.widget<Text>(find.text('Copiar')).style?.color;
    expect(cor, isNotNull);
    expect(cor, isNot(Colors.white));
  });
}
