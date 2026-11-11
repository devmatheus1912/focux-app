import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/navigation/fx_aba_topo.dart';

void main() {
  testWidgets('segundo toque na aba sobe a lista ao topo', (tester) async {
    late BuildContext ctx;
    final controller = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return ListView.builder(
              controller: controller,
              itemCount: 100,
              itemBuilder: (_, i) => SizedBox(height: 60, child: Text('$i')),
            );
          },
        ),
      ),
    );
    controller.jumpTo(1200);
    await tester.pump();
    fxRolarAbaAtivaAoTopo(ctx);
    await tester.pumpAndSettle();
    expect(controller.offset, 0);
  });

  testWidgets('aba fora da tela (TickerMode desligado) não rola', (
    tester,
  ) async {
    late BuildContext ctx;
    final escondida = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            ctx = context;
            return TickerMode(
              enabled: false,
              child: ListView.builder(
                controller: escondida,
                itemCount: 100,
                itemBuilder: (_, i) => SizedBox(height: 60, child: Text('$i')),
              ),
            );
          },
        ),
      ),
    );
    escondida.jumpTo(600);
    await tester.pump();
    fxRolarAbaAtivaAoTopo(ctx);
    await tester.pumpAndSettle();
    expect(escondida.offset, 600);
  });
}
