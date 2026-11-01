import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/design_tokens.dart';
import 'package:focux_app/core/widgets/operational_metric_tile.dart';

Widget _wrap(Widget child, {required double textScaleFactor}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('OperationalMetricTile exposes semantics label', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _wrap(
        const OperationalMetricTile(
          label: 'Situação do aluno',
          value: '82',
          hint: 'Treinos e pagamentos',
          color: Colors.blue,
          isDark: false,
          semanticsLabel: 'Situação do aluno 82',
        ),
        textScaleFactor: 1,
      ),
    );

    expect(
      tester.getSemantics(find.byType(OperationalMetricTile)).label,
      startsWith('Situação do aluno 82'),
    );
    handle.dispose();
  });

  testWidgets('alert emphasis keeps fill/border without side rail', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const OperationalMetricTile(
          label: 'Risco',
          value: '3',
          hint: 'Alunos pedem contato',
          color: EagleTokens.warn,
          isDark: false,
          emphasis: OperationalMetricEmphasis.alert,
        ),
        textScaleFactor: 1,
      ),
    );

    final decorated = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox));
    expect(
      decorated.any((w) {
        final d = w.decoration;
        return d is BoxDecoration &&
            d.borderRadius == BorderRadius.circular(999);
      }),
      isFalse,
      reason: 'alert não usa rail lateral (barra 3px)',
    );
    expect(find.text('RISCO'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

}
