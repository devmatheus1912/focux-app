import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focux_app/core/widgets/fx_motion.dart';

/// Reproduz a entrevista da landing: etapa trocada por chave, com campo focado.
void main() {
  for (final (nome, rolagem) in <(String, Widget Function(List<Widget>))>[
    ('ListView', (filhos) => ListView(children: filhos)),
    (
      'SingleChildScrollView',
      (filhos) => SingleChildScrollView(child: Column(children: filhos)),
    ),
  ]) {
    testWidgets('$nome: etapa nova aparece depois da troca', (tester) async {
      var etapa = 0;
      late StateSetter trocar;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                trocar = setState;
                return rolagem([
                  const SizedBox(height: 40),
                  KeyedSubtree(
                    key: ValueKey(etapa),
                    child: FxStaggerItem(
                      index: 0,
                      child: Column(
                        children: [
                          Text('etapa $etapa'),
                          TextFormField(key: ValueKey('campo $etapa')),
                        ],
                      ),
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('campo 0')));
      await tester.pump();

      FocusManager.instance.primaryFocus?.unfocus();
      trocar(() => etapa = 1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(find.text('etapa 1'), findsOneWidget);
      final opacidade = tester.widget<Opacity>(
        find.ancestor(of: find.text('etapa 1'), matching: find.byType(Opacity)),
      );
      expect(opacidade.opacity, 1);
      expect(tester.getSize(find.text('etapa 1')).height, greaterThan(0));
    });
  }
}
