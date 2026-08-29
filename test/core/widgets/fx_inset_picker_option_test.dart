import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_option.dart';
import 'package:focux_app/core/widgets/fx_settings_group.dart';

void main() {
  testWidgets('picker option preenche largura do grupo inset', (tester) async {
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

    final cardRect = tester.getRect(groupCard);
    final rowRect = tester.getRect(selectedRow);

    expect(rowRect.left, cardRect.left);
    expect(rowRect.right, cardRect.right);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
