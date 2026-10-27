import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_action_link.dart';
import 'package:focux_app/core/widgets/fx_loading.dart';
import 'package:focux_app/core/widgets/fx_tonal_button.dart';

import '../../support/dynamic_type_harness.dart';

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('FxActionLink: texto com seta, 44 de toque e chama onTap', (
    tester,
  ) async {
    var n = 0;
    await tester.pumpWidget(
      _app(FxActionLink(label: 'Ver todos', onTap: () => n++)),
    );
    final alvo = tester.getSize(find.byType(InkWell));
    expect(alvo.height, greaterThanOrEqualTo(44));
    expect(alvo.width, greaterThanOrEqualTo(44));
    await tester.tap(find.text('Ver todos'));
    expect(n, 1);
  });

  testWidgets('FxActionLink desabilitado não chama e lê como botão', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const FxActionLink(label: 'Ver todos', onTap: null)),
    );
    expect(
      tester.getSemantics(find.byType(FxActionLink)),
      matchesSemantics(
        label: 'Ver todos',
        isButton: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('FxTonalButton: ícone, 44 de toque, carregando bloqueia', (
    tester,
  ) async {
    var n = 0;
    await tester.pumpWidget(
      _app(
        FxTonalButton(
          label: 'Adicionar',
          icon: Icons.add_rounded,
          onPressed: () => n++,
        ),
      ),
    );
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(
      tester.getSize(find.byType(InkWell)).height,
      greaterThanOrEqualTo(36),
    );
    await tester.tap(find.text('Adicionar'));
    expect(n, 1);

    await tester.pumpWidget(
      _app(
        FxTonalButton(label: 'Adicionar', loading: true, onPressed: () => n++),
      ),
    );
    await tester.tap(find.text('Adicionar'));
    expect(n, 1);
    expect(find.byType(FxLoading), findsOneWidget);
  });

  testWidgets('FxTonalButton usa o rótulo semântico específico', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        FxTonalButton(
          label: 'Adicionar',
          semanticLabel: 'Adicionar em Aquecimento',
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Adicionar em Aquecimento'), findsOneWidget);
    handle.dispose();
  });

  for (final tela in kDynamicTypeTelas) {
    testWidgets('peças aguentam ${descreverTela(tela)}', (tester) async {
      usarDynamicTypeMaximo(tester, tela);
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FxActionLink(label: 'Ver todos os 6 sinais', onTap: () {}),
              FxTonalButton(
                label: 'Montar ficha',
                icon: Icons.add_rounded,
                onPressed: () {},
              ),
            ],
          ),
          dark: true,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
