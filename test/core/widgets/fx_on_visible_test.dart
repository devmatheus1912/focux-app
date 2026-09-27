import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_on_visible.dart';

Widget _lista({
  required ScrollController controller,
  required VoidCallback onVisible,
  bool tickers = true,
}) {
  return MaterialApp(
    home: TickerMode(
      enabled: tickers,
      child: Scaffold(
        body: SizedBox(
          height: 600,
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 900),
              FxOnVisible(
                onVisible: onVisible,
                child: const SizedBox(height: 200, child: Text('alvo')),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('fora da tela não dispara; ao rolar até ele dispara uma vez', (
    tester,
  ) async {
    final controller = ScrollController();
    var vistos = 0;
    await tester.pumpWidget(
      _lista(controller: controller, onVisible: () => vistos++),
    );
    await tester.pump();
    expect(vistos, 0);

    controller.jumpTo(600);
    await tester.pump();
    expect(vistos, 1);

    controller.jumpTo(620);
    await tester.pump();
    expect(vistos, 1);
  });

  testWidgets('sai e volta: conta de novo', (tester) async {
    final controller = ScrollController();
    var vistos = 0;
    await tester.pumpWidget(
      _lista(controller: controller, onVisible: () => vistos++),
    );
    controller.jumpTo(600);
    await tester.pump();
    controller.jumpTo(0);
    await tester.pump();
    controller.jumpTo(600);
    await tester.pump();
    expect(vistos, 2);
  });

  testWidgets('aba em segundo plano não conta', (tester) async {
    final controller = ScrollController();
    var vistos = 0;
    await tester.pumpWidget(
      _lista(controller: controller, onVisible: () => vistos++, tickers: false),
    );
    controller.jumpTo(600);
    await tester.pump();
    expect(vistos, 0);
  });

  testWidgets('menos da metade à vista ainda não conta', (tester) async {
    final controller = ScrollController();
    var vistos = 0;
    await tester.pumpWidget(
      _lista(controller: controller, onVisible: () => vistos++),
    );
    controller.jumpTo(350);
    await tester.pump();
    expect(vistos, 0);
  });
}
