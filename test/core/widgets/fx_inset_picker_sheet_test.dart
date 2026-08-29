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

  test('perfil appearance usa picker canônico', () {
    final source = File(
      'lib/features/perfil/widgets/perfil_appearance_section.dart',
    ).readAsStringSync();

    expect(PerfilAppearanceSection.labelFor(ThemeMode.light), 'Claro');
    expect(source, contains('showFxInsetPickerSheet'));
    expect(source, contains('FxInsetPickerSheetItem'));
    expect(source, isNot(contains('Icons.check,')));
  });
}
