import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_option.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_sheet.dart';
import 'package:focux_app/features/perfil/widgets/perfil_appearance_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('showFxInsetPickerSheet retorna valor selecionado', (tester) async {
    ThemeMode? picked;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () async {
                      picked = await showFxInsetPickerSheet<ThemeMode>(
                        context,
                        title: 'Aparência',
                        headerIcon: Icons.dark_mode_outlined,
                        selected: ThemeMode.system,
                        items: const [
                          FxInsetPickerSheetItem(
                            value: ThemeMode.system,
                            label: 'Sistema',
                          ),
                          FxInsetPickerSheetItem(
                            value: ThemeMode.dark,
                            label: 'Escuro',
                          ),
                        ],
                      );
                    },
                    child: const Text('abrir'),
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(FxInsetPickerOption), findsNWidgets(2));
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(picked, ThemeMode.dark);
  });

  testWidgets('lista longa abre com o item escolhido à vista', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => TextButton(
                    onPressed: () {
                      showFxInsetPickerSheet<int>(
                        context,
                        title: 'Mês',
                        selected: 29,
                        items: [
                          for (var i = 0; i < 30; i++)
                            FxInsetPickerSheetItem(value: i, label: 'Item $i'),
                        ],
                      );
                    },
                    child: const Text('abrir'),
                  ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Item 29').hitTestable(), findsOneWidget);
  });

  test('perfil appearance mostra as três opções à vista, sem sheet', () {
    final source = File(
      'lib/features/perfil/widgets/perfil_appearance_section.dart',
    ).readAsStringSync();

    expect(PerfilAppearanceSection.labelFor(ThemeMode.light), 'Claro');
    expect(source, contains('FxChoiceStrip'));
    expect(source, isNot(contains('showFxInsetPickerSheet')));
    expect(source, isNot(contains('Icons.check,')));
  });
}
