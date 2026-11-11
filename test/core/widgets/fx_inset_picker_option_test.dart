import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_option.dart';
import 'package:focux_app/core/widgets/fx_settings_group.dart';
import 'package:focux_app/core/theme/fx_icons.dart';

void main() {
  testWidgets('toque na linha inteira, seleção recuada e arredondada', (tester) async {
    const accent = Color(0xFF0D9488);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: FxSettingsGroup(
              accent: accent,
              edgeToEdgeRows: true,
              children: FxInsetPickerOption.list(
                accent: accent,
                items: [
                  FxInsetPickerOptionSpec(
                    label: 'Peito',
                    selected: true,
                    onTap: () {},
                  ),
                  FxInsetPickerOptionSpec(
                    label: 'Costas',
                    selected: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final groupCard = find.byWidgetPredicate(
      (widget) => widget is DecoratedBox && widget.child is ClipRRect,
    );
    final selectedRow = find.ancestor(
      of: find.text('Peito'),
      matching: find.byType(InkWell),
    );
    final selecao = find.byKey(const ValueKey('fx-inset-picker-selecao'));

    final cardRect = tester.getRect(groupCard);
    final rowRect = tester.getRect(selectedRow);
    final selecaoRect = tester.getRect(selecao);

    // O toque vale a linha toda; o fundo da escolhida fica recuado.
    expect(rowRect.left, cardRect.left);
    expect(rowRect.right, cardRect.right);
    expect(selecaoRect.left, rowRect.left + FxInsetPickerOption.recuoSelecao);
    expect(selecaoRect.right, rowRect.right - FxInsetPickerOption.recuoSelecao);
    expect(find.byIcon(FxIcons.check), findsOneWidget);
  });

  testWidgets('semMoldura não desenha o cartão', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FxSettingsGroup(
            semMoldura: true,
            edgeToEdgeRows: true,
            children: const [Text('Item')],
          ),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is DecoratedBox && widget.child is ClipRRect,
      ),
      findsNothing,
    );
    expect(find.text('Item'), findsOneWidget);
  });
}
