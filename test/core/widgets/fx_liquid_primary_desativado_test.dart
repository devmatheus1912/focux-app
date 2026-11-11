import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_motion.dart';

BoxDecoration _decoracao(WidgetTester tester) {
  final ink = tester.widget<Ink>(
    find.descendant(of: find.byType(FxLiquidPrimaryButton), matching: find.byType(Ink)),
  );
  return ink.decoration! as BoxDecoration;
}

void main() {
  testWidgets('desativado não parece ativo (sem degradê) e o leitor diz', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FxLiquidPrimaryButton(label: 'Salvar marca')),
      ),
    );
    final desligado = _decoracao(tester);
    expect(desligado.gradient, isNull);
    expect(desligado.color, isNotNull);
    final widget = tester.widget<Semantics>(
      find
          .descendant(
            of: find.byType(FxLiquidPrimaryButton),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.enabled != null,
            ),
          )
          .first,
    );
    expect(widget.properties.enabled, isFalse);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxLiquidPrimaryButton(label: 'Salvar marca', onPressed: () {}),
        ),
      ),
    );
    expect(_decoracao(tester).gradient, isNotNull);
    semantics.dispose();
  });
}
