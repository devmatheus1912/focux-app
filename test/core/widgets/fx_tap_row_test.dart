import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_tap_row.dart';

import 'fx_kit_host.dart';

void main() {
  testWidgets('mostra título, subtítulo e seta, e o toque chama o callback', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      kitHost(
        FxTapRow(
          title: 'Treino A',
          subtitle: '5 exercícios',
          onTap: () => toques++,
        ),
      ),
    );
    expect(find.text('Treino A'), findsOneWidget);
    expect(find.text('5 exercícios'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

    await tester.tap(find.text('Treino A'));
    expect(toques, 1);
  });

  testWidgets('variante vazio mostra "+" no lugar da seta', (tester) async {
    await tester.pumpWidget(
      kitHost(FxTapRow(title: 'Adicionar treino', vazio: true, onTap: () {})),
    );
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('trailing substitui a seta', (tester) async {
    await tester.pumpWidget(
      kitHost(
        FxTapRow(title: 'Treino C', trailing: const Text('Montar'), onTap: () {}),
      ),
    );
    expect(find.text('Montar'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
  });

  testWidgets('altura mínima de 56 dp e Semantics de botão', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      kitHost(FxTapRow(title: 'Treino B', subtitle: 'Vazio', onTap: () {})),
    );
    expect(
      tester.getSize(find.byType(FxTapRow)).height,
      greaterThanOrEqualTo(FxTapRow.alturaMin),
    );
    final semantics = tester.getSemantics(find.byType(FxTapRow));
    expect(semantics.label, 'Treino B, Vazio');
    expect(semantics.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  for (final escuro in [false, true]) {
    testWidgets('texto 2.0 sem overflow (escuro: $escuro)', (tester) async {
      await tester.pumpWidget(
        kitHost(
          FxTapRow(
            title: 'Treino de membros inferiores',
            subtitle: '12 exercícios · 2º treino',
            onTap: () {},
          ),
          dark: escuro,
          textScale: 2,
          width: 240,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
