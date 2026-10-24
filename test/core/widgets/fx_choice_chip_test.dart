import 'package:flutter/material.dart';
import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_choice_chip.dart';

import 'fx_kit_host.dart';

void main() {
  testWidgets('toque chama o callback e o chip mostra o rótulo', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      kitHost(FxChoiceChip(label: '4', selected: false, onTap: () => toques++)),
    );
    await tester.tap(find.text('4'));
    expect(toques, 1);
  });

  testWidgets('expõe Semantics de botão e de selecionado', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      kitHost(FxChoiceChip(label: '4', selected: true, onTap: () {})),
    );
    final semantics = tester.getSemantics(find.byType(FxChoiceChip));
    expect(semantics.label, '4');
    expect(semantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(semantics.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('alvo de toque tem 48 dp ou mais', (tester) async {
    await tester.pumpWidget(
      kitHost(FxChoiceChip(label: '2', selected: false, onTap: () {})),
    );
    final tamanho = tester.getSize(find.byType(FxChoiceChip));
    expect(tamanho.height, greaterThanOrEqualTo(48));
    expect(tamanho.width, greaterThanOrEqualTo(48));
  });

  testWidgets('não estica dentro de uma Wrap', (tester) async {
    await tester.pumpWidget(
      kitHost(
        Wrap(
          children: [
            FxChoiceChip(label: '2', selected: false, onTap: () {}),
            FxChoiceChip(label: '3', selected: true, onTap: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(FxChoiceChip).first).width,
      lessThan(120),
    );
  });

  testWidgets('desabilitado não dispara o callback', (tester) async {
    await tester.pumpWidget(
      kitHost(const FxChoiceChip(label: '5', selected: false, onTap: null)),
    );
    await tester.tap(find.text('5'), warnIfMissed: false);
    expect(tester.takeException(), isNull);
  });

  for (final escuro in [false, true]) {
    testWidgets('texto 2.0 sem overflow (escuro: $escuro)', (tester) async {
      await tester.pumpWidget(
        kitHost(
          FxChoiceChip(label: 'Hipertrofia', selected: true, onTap: () {}),
          dark: escuro,
          textScale: 2,
          width: 200,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
