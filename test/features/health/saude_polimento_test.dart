import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/health/widgets/prontidao_card.dart';
import 'package:focux_app/features/health/widgets/saude_cards.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget filho) => MaterialApp(home: Scaffold(body: Center(child: filho)));

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('cartão sem dado mostra "Sem registro" pequeno, sem unidade', (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 180,
          child: SaudeMetricTile(
            icone: Icons.local_fire_department_outlined,
            rotulo: 'Calorias ativas',
            valor: '--',
            unidade: 'kcal',
            apoio: 'Sem energia ativa hoje',
          ),
        ),
      ),
    );
    expect(find.text('--'), findsNothing);
    expect(find.textContaining('Sem registro'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
  });

  testWidgets('sem nota, a prontidão é uma faixa sem anel e com "Como registrar"', (tester) async {
    var registrou = false;
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        ProntidaoCard(
          recovery: null,
          onPorQue: () {},
          onVerTreino: () {},
          onComoRegistrar: () => registrou = true,
        ),
      ),
    );
    expect(find.byType(ProntidaoAnel), findsNothing);
    expect(find.text('Sem sono registrado'), findsOneWidget);
    expect(tester.getSize(find.byType(ProntidaoCard)).height, lessThan(160));
    await tester.tap(find.text('Como registrar'));
    expect(registrou, isTrue);
    expect(tester.takeException(), isNull);
  });
}
