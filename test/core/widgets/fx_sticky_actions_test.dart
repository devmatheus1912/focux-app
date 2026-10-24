import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_sticky_actions.dart';

import 'fx_kit_host.dart';

Widget _tela({
  VoidCallback? onPrimary,
  VoidCallback? onSecondary,
  bool loading = false,
  String? secundario = 'Salvar como modelo',
}) => Column(
  children: [
    Expanded(
      child: ListView(
        children: [
          for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text('Linha $i')),
        ],
      ),
    ),
    FxStickyActions(
      primaryLabel: 'Pronto',
      onPrimary: onPrimary,
      loading: loading,
      secondaryLabel: secundario,
      onSecondary: onSecondary,
    ),
  ],
);

void main() {
  testWidgets('botão principal e secundário chamam os callbacks', (
    tester,
  ) async {
    var principal = 0;
    var secundario = 0;
    await tester.pumpWidget(
      kitHost(
        SizedBox(
          height: 700,
          child: _tela(onPrimary: () => principal++, onSecondary: () => secundario++),
        ),
      ),
    );
    await tester.tap(find.text('Pronto'));
    await tester.tap(find.text('Salvar como modelo'));
    expect(principal, 1);
    expect(secundario, 1);
  });

  testWidgets('sem secundário mostra só o principal', (tester) async {
    await tester.pumpWidget(
      kitHost(SizedBox(height: 700, child: _tela(onPrimary: () {}, secundario: null))),
    );
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Pronto'), findsOneWidget);
  });

  testWidgets('carregando desabilita os dois botões', (tester) async {
    var toques = 0;
    await tester.pumpWidget(
      kitHost(
        SizedBox(
          height: 700,
          child: _tela(onPrimary: () => toques++, onSecondary: () => toques++, loading: true),
        ),
      ),
    );
    await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
    expect(toques, 0);
  });

  testWidgets('o fim da lista fica visível acima da barra', (tester) async {
    await tester.pumpWidget(
      kitHost(SizedBox(height: 700, child: _tela(onPrimary: () {}))),
    );
    await tester.drag(find.byType(ListView), const Offset(0, -5000));
    await tester.pumpAndSettle();

    final ultimaLinha = tester.getBottomLeft(find.text('Linha 29')).dy;
    final topoDaBarra = tester.getTopLeft(find.byType(FxStickyActions)).dy;
    expect(ultimaLinha, lessThanOrEqualTo(topoDaBarra));
  });
}
