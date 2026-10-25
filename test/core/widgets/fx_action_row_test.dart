import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_action_row.dart';

import 'fx_kit_host.dart';

void main() {
  testWidgets('mostra pessoa, motivo e verbo; a linha toda toca', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      kitHost(
        FxActionRow(
          titulo: 'Hugo',
          motivo: '9 dias sem treinar',
          verbo: 'Chamar',
          onTap: () => toques++,
        ),
      ),
    );
    expect(find.text('Hugo'), findsOneWidget);
    expect(find.text('9 dias sem treinar'), findsOneWidget);
    expect(find.text('Chamar'), findsOneWidget);

    await tester.tap(find.text('Hugo'));
    await tester.tap(find.text('Chamar'));
    expect(toques, 2);
  });

  testWidgets('altura mínima de 56 dp e Semantics de botão com o verbo', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      kitHost(
        FxActionRow(titulo: 'Ana', motivo: 'R\$ 150 vencida há 3 dias', verbo: 'Cobrar', onTap: () {}),
      ),
    );
    expect(
      tester.getSize(find.byType(FxActionRow)).height,
      greaterThanOrEqualTo(FxActionRow.alturaMin),
    );
    final semantics = tester.getSemantics(find.byType(FxActionRow));
    expect(semantics.label, 'Cobrar, Ana, R\$ 150 vencida há 3 dias');
    expect(semantics.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  for (final escuro in [false, true]) {
    testWidgets('texto 2.0 sem overflow (escuro: $escuro)', (tester) async {
      await tester.pumpWidget(
        kitHost(
          FxActionRow(
            titulo: 'Maria Fernanda de Albuquerque',
            motivo: 'Mensalidade de R\$ 1.250 vencida há 12 dias',
            verbo: 'Cobrar',
            onTap: () {},
          ),
          dark: escuro,
          textScale: 2,
          width: 280,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
