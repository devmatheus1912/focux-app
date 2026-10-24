import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_status_pill.dart';

import 'fx_kit_host.dart';

void main() {
  for (final tom in FxPillTone.values) {
    testWidgets('tom ${tom.name} mostra o texto, em claro e escuro', (
      tester,
    ) async {
      for (final escuro in [false, true]) {
        await tester.pumpWidget(
          kitHost(FxStatusPill(label: 'Vence em 7 dias', tone: tom), dark: escuro),
        );
        expect(find.text('Vence em 7 dias'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('sucesso ganha check por padrão; os outros não', (tester) async {
    await tester.pumpWidget(
      kitHost(const FxStatusPill(label: 'Pronto', tone: FxPillTone.success)),
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.pumpWidget(
      kitHost(const FxStatusPill(label: 'Em montagem', tone: FxPillTone.warning)),
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('ícone próprio vale em qualquer tom', (tester) async {
    await tester.pumpWidget(
      kitHost(
        const FxStatusPill(
          label: 'Vencida',
          tone: FxPillTone.danger,
          icon: Icons.schedule_rounded,
        ),
      ),
    );
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
  });

  testWidgets('expõe o rótulo em Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      kitHost(const FxStatusPill(label: 'Pronto', tone: FxPillTone.success)),
    );
    expect(tester.getSemantics(find.byType(FxStatusPill)).label, 'Pronto');
    handle.dispose();
  });

  testWidgets('texto 2.0 em largura curta não estoura', (tester) async {
    await tester.pumpWidget(
      kitHost(
        const FxStatusPill(label: 'Ficha vence em 7 dias', tone: FxPillTone.warning),
        textScale: 2,
        width: 140,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
