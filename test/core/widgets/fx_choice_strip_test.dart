import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_choice_chip.dart';
import 'package:focux_app/core/widgets/fx_choice_strip.dart';

import 'fx_kit_host.dart';

const _itens = [
  FxChoiceItem(value: 2, label: '2'),
  FxChoiceItem(value: 3, label: '3'),
  FxChoiceItem(value: 4, label: '4'),
  FxChoiceItem(value: 5, label: '5'),
];

void main() {
  testWidgets('devolve o valor tocado e marca o selecionado', (tester) async {
    int? escolhido;
    await tester.pumpWidget(
      kitHost(
        FxChoiceStrip<int>(
          itens: _itens,
          selecionado: 3,
          onSelecionar: (v) => escolhido = v,
        ),
      ),
    );
    final chips = tester.widgetList<FxChoiceChip>(find.byType(FxChoiceChip));
    expect(chips.where((c) => c.selected).map((c) => c.label), ['3']);

    await tester.tap(find.text('5'));
    expect(escolhido, 5);
  });

  testWidgets('rola na horizontal quando não cabe, sem overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      kitHost(
        FxChoiceStrip<int>(
          itens: _itens,
          selecionado: 2,
          onSelecionar: (_) {},
        ),
        width: 120,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('quebrar usa Wrap em vez de rolagem', (tester) async {
    await tester.pumpWidget(
      kitHost(
        FxChoiceStrip<int>(
          itens: _itens,
          selecionado: 2,
          onSelecionar: (_) {},
          quebrar: true,
        ),
        width: 120,
      ),
    );
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
