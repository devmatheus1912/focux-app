import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/design_system.dart';

void main() {
  test('barrel expõe o stack canônico da Home', () {
    expect(TokensStrip.rCard, 12);
    expect(TokensStrip.rInput, 8);
    expect(TokensStrip.s4, 16);
    expect(
      FocuxHubTypography.body(color: Colors.black).fontSize,
      TokensStrip.fontBody,
    );
  });

  testWidgets('FxStripCard usa decoração strip e responde a toque', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FxStripCard(
              semanticsLabel: 'Abrir card',
              onTap: () => taps++,
              child: const Text('conteúdo'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('conteúdo'), findsOneWidget);

    final decorated = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('conteúdo'), matching: find.byType(DecoratedBox))
          .first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(TokensStrip.rCard));
    expect(decoration.border, isNotNull);

    await tester.tap(find.text('conteúdo'));
    expect(taps, 1);
  });

  testWidgets('FxStripCard sem onTap não cria InkWell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FxStripCard(child: Text('estático'))),
      ),
    );
    expect(
      find.ancestor(of: find.text('estático'), matching: find.byType(InkWell)),
      findsNothing,
    );
  });
}
