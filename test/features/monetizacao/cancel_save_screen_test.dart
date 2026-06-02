import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/features/monetizacao/screens/cancel_save_screen.dart';

void main() {
  testWidgets('CancelSaveScreen shows motivos and readable subtitle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CancelSaveScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Que pena que você quer ir embora.'), findsOneWidget);
    expect(
      find.text(
        'Selecione um motivo — mostramos uma alternativa personalizada aqui embaixo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Está caro demais agora'), findsOneWidget);
    expect(find.text('Antes de cancelar…'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsNothing);
  });
}
