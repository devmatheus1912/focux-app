import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/theme/fx_page_transitions_builder.dart';
import 'package:focux_app/core/widgets/fx_fundo_da_pagina.dart';

/// Toda página pinta o próprio fundo: na transição a tela de baixo não aparece
/// através da de cima (SPEC-transicao-cromo).
void main() {
  test('todos os sistemas passam pelo fundo opaco', () {
    for (final b in fxPremiumPageTransitions.builders.values) {
      expect(b, isA<FxFundoOpacoTransitionsBuilder>());
    }
  });

  testWidgets('no meio da transição, cada página tem o seu fundo', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: ThemeData(
          platform: TargetPlatform.iOS,
          pageTransitionsTheme: fxPremiumPageTransitions,
        ),
        home: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Text('embaixo'),
        ),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          backgroundColor: Colors.transparent,
          body: Text('em cima'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    // As duas páginas estão na tela durante o deslize, cada uma com fundo.
    expect(find.text('embaixo'), findsOneWidget);
    expect(find.text('em cima'), findsOneWidget);
    expect(find.byType(FxFundoDaPagina), findsNWidgets(2));
    expect(
      find.ancestor(of: find.text('em cima'), matching: find.byType(FxFundoDaPagina)),
      findsOneWidget,
    );
    await tester.pumpAndSettle();
  });
}
