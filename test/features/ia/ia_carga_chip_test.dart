import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/ia/widgets/ia_carga_chip.dart';

void main() {
  testWidgets('suggested chip legível com textScaler 2.0', (tester) async {
    tester.view.physicalSize = const Size(390, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: const Scaffold(
            body: IaCargaChip(
              label: 'Sugerido',
              valor: '82,5kg 3x12',
              color: Color(0xFF26A69A),
              deltaLabel: '+2,5 kg',
            ),
          ),
        ),
      ),
    );

    expect(find.text('82,5kg 3x12'), findsOneWidget);
    expect(find.text('+2,5 kg'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
