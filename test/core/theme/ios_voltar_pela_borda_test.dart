import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_page_transitions_builder.dart';

/// No iPhone, arrastar da borda esquerda volta: o gesto vem da transição
/// Cupertino do tema. A transição própria não tem gesto nenhum.
void main() {
  testWidgets('iPhone volta arrastando da borda', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(pageTransitionsTheme: fxPremiumPageTransitions),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder:
                                (_) => const Scaffold(body: Text('detalhe')),
                          ),
                        ),
                    child: const Text('abrir'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('detalhe'), findsOneWidget);

    // Arrasto contínuo a partir da borda, como o dedo faz.
    await tester.timedDragFrom(
      const Offset(2, 300),
      const Offset(600, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(find.text('detalhe'), findsNothing);
    expect(find.text('abrir'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('Android segue com a transição própria', (tester) async {
    expect(
      fxPremiumPageTransitions.builders[TargetPlatform.android],
      isA<FxPremiumPageTransitionsBuilder>(),
    );
  });
}
