import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_form_sheet.dart';

void main() {
  testWidgets('showFxFormSheet confirma e cancela', (tester) async {
    var result = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showFxFormSheet(
                  context,
                  title: 'Novo item',
                  confirmLabel: 'Criar',
                  child: const TextField(),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Novo item'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result, isFalse);

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Criar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(result, isTrue);
  });

  testWidgets('dispose do controller logo após fechar não quebra a saída', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final ctrl = TextEditingController();
                try {
                  await showFxFormSheet(
                    context,
                    title: 'Recado',
                    confirmLabel: 'Enviar',
                    child: TextField(controller: ctrl),
                  );
                } finally {
                  ctrl.dispose();
                }
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'oi');
    await tester.tap(find.text('Enviar'));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('Recado'), findsNothing);
  });

  testWidgets('showFxNoticeSheet fecha no Entendi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showFxNoticeSheet(
                context,
                title: 'Pronto',
                message: 'Tudo certo.',
              ),
              child: const Text('avisar'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('avisar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pronto'), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Pronto'), findsNothing);
  });
}
