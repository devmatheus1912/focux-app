import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_option.dart';
import 'package:focux_app/core/widgets/fx_inset_picker_sheet.dart';
import 'package:focux_app/features/perfil/widgets/perfil_appearance_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focux_app/core/theme/fx_icons.dart';

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
                        headerIcon: FxIcons.sono,
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

  test('perfil appearance em uma linha que abre a escolha', () {
    final source = File(
      'lib/features/perfil/widgets/perfil_appearance_section.dart',
    ).readAsStringSync();

    expect(PerfilAppearanceSection.labelFor(ThemeMode.light), 'Claro');
    expect(source, contains('showFxInsetPickerSheet'));
    expect(source, isNot(contains('FxChoiceStrip')));
    expect(source, isNot(contains('FxIcons.check,')));
    // Ícones de tema (Phosphor): sol, lua e celular; a linha mostra o atual.
    expect(PerfilAppearanceSection.iconFor(ThemeMode.light), FxIcons.temaClaro);
    expect(PerfilAppearanceSection.iconFor(ThemeMode.dark), FxIcons.temaEscuro);
    expect(
      PerfilAppearanceSection.iconFor(ThemeMode.system),
      FxIcons.temaSistema,
    );
  });

  test('folha de escolha sem moldura dentro da folha', () {
    final source = File(
      'lib/core/widgets/fx_inset_picker_sheet.dart',
    ).readAsStringSync();
    expect(source, contains('semMoldura: true'));
  });
}
