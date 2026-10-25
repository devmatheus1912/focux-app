import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_metric_strip.dart';

import 'fx_kit_host.dart';

void main() {
  testWidgets('cada número leva à sua lista', (tester) async {
    final toques = <String>[];
    await tester.pumpWidget(
      kitHost(
        FxMetricStrip(
          metricas: [
            FxMetric(valor: 3, rotulo: 'Treinaram hoje', onTap: () => toques.add('treinaram')),
            FxMetric(valor: 1, rotulo: 'Em risco', alerta: true, onTap: () => toques.add('risco')),
            FxMetric(valor: 0, rotulo: 'Fichas a vencer', onTap: () => toques.add('fichas')),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Treinaram hoje'));
    await tester.tap(find.text('Em risco'));
    await tester.tap(find.text('Fichas a vencer'));
    expect(toques, ['treinaram', 'risco', 'fichas']);
  });

  testWidgets('zero fica apagado e nunca ganha cor de alerta', (tester) async {
    await tester.pumpWidget(
      kitHost(
        FxMetricStrip(
          metricas: [
            FxMetric(valor: 0, rotulo: 'Em risco', alerta: true, onTap: () {}),
            FxMetric(valor: 2, rotulo: 'Em risco', alerta: true, onTap: () {}),
          ],
        ),
      ),
    );
    final cores = tester
        .widgetList<Text>(find.byWidgetPredicate((w) => w is Text && (w.data == '0' || w.data == '2')))
        .map((t) => t.style!.color!)
        .toList();
    expect(cores[0], isNot(cores[1]));
    expect(cores[0].a, lessThan(1));
  });

  testWidgets('Semantics junta número e rótulo', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      kitHost(FxMetricStrip(metricas: [FxMetric(valor: 4, rotulo: 'Em risco', onTap: () {})])),
    );
    expect(find.bySemanticsLabel('4 Em risco'), findsOneWidget);
    handle.dispose();
  });

  for (final escuro in [false, true]) {
    testWidgets('texto 2.0 sem overflow (escuro: $escuro)', (tester) async {
      await tester.pumpWidget(
        kitHost(
          FxMetricStrip(
            metricas: [
              FxMetric(valor: 12, rotulo: 'Treinaram hoje', onTap: () {}),
              FxMetric(valor: 3, rotulo: 'Em risco', onTap: () {}),
              FxMetric(valor: 1, rotulo: 'Fichas a vencer', onTap: () {}),
            ],
          ),
          dark: escuro,
          textScale: 2,
          width: 340,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
