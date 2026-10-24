import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_action_sheet.dart';

import 'fx_kit_host.dart';

enum _Acao { recomecar, duplicar, apagar }

Widget _abridor(void Function(_Acao?) aoFechar) => Builder(
  builder: (context) => TextButton(
    onPressed: () async {
      final escolhida = await showFxActionSheet<_Acao>(
        context,
        title: 'Ficha de Hugo',
        itens: const [
          FxActionSheetItem(
            value: _Acao.recomecar,
            label: 'Recomeçar ficha',
            icon: Icons.restart_alt_rounded,
          ),
          FxActionSheetItem(
            value: _Acao.duplicar,
            label: 'Duplicar como base',
            icon: Icons.copy_rounded,
          ),
          FxActionSheetItem(
            value: _Acao.apagar,
            label: 'Limpar semana',
            icon: Icons.delete_outline_rounded,
            destructive: true,
          ),
        ],
      );
      aoFechar(escolhida);
    },
    child: const Text('Abrir'),
  ),
);

void main() {
  testWidgets('lista as ações e devolve a escolhida', (tester) async {
    _Acao? resultado;
    await tester.pumpWidget(kitHost(_abridor((a) => resultado = a)));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Ficha de Hugo'), findsOneWidget);
    expect(find.text('Recomeçar ficha'), findsOneWidget);
    expect(find.text('Duplicar como base'), findsOneWidget);
    expect(find.text('Limpar semana'), findsOneWidget);

    await tester.tap(find.text('Duplicar como base'));
    await tester.pumpAndSettle();
    expect(resultado, _Acao.duplicar);
  });

  testWidgets('fechar sem escolher devolve null', (tester) async {
    var fechou = false;
    _Acao? resultado = _Acao.apagar;
    await tester.pumpWidget(
      kitHost(
        _abridor((a) {
          fechou = true;
          resultado = a;
        }),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(fechou, isTrue);
    expect(resultado, isNull);
  });

  testWidgets('itens têm Semantics de botão e o menu aguenta texto 2.0', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(kitHost(_abridor((_) {}), textScale: 2));
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Recomeçar ficha'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
